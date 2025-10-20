using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using Serilog;
using Serilog.Formatting.Compact;
using System.Diagnostics;

// Configure Serilog for structured logging
Log.Logger = new LoggerConfiguration()
    .Enrich.FromLogContext()
    .Enrich.WithMachineName()
    .Enrich.WithThreadId()
    .Enrich.WithProperty("Application", "SampleApp")
    .Enrich.WithProperty("Environment", Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Production")
    .WriteTo.Console(new CompactJsonFormatter())
    .CreateLogger();

var builder = WebApplication.CreateBuilder(args);

// Add Serilog
builder.Host.UseSerilog();

// Configure OpenTelemetry
builder.Services.AddOpenTelemetry()
    .WithTracing(tracerProviderBuilder =>
    {
        tracerProviderBuilder
            .AddSource("SampleApp")
            .SetResourceBuilder(ResourceBuilder.CreateDefault()
                .AddService("sample-app")
                .AddAttributes(new Dictionary<string, object>
                {
                    ["deployment.environment"] = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "production",
                    ["service.version"] = Environment.GetEnvironmentVariable("APP_VERSION") ?? "1.0.0"
                }))
            .AddAspNetCoreInstrumentation(options =>
            {
                options.RecordException = true;
                options.EnrichWithHttpRequest = (activity, httpRequest) =>
                {
                    activity.SetTag("http.request.correlation_id", Activity.Current?.Id ?? Guid.NewGuid().ToString());
                };
            })
            .AddHttpClientInstrumentation()
            .AddOtlpExporter(options =>
            {
                options.Endpoint = new Uri(Environment.GetEnvironmentVariable("OTEL_EXPORTER_OTLP_ENDPOINT") ?? "http://tempo:4317");
            });
    });

// Initialize Pyroscope profiler
Pyroscope.Profiler.Profiler.Start(
    applicationName: "sample-app",
    serverAddress: Environment.GetEnvironmentVariable("PYROSCOPE_SERVER_ADDRESS") ?? "http://pyroscope:4040",
    tags: new Dictionary<string, string>
    {
        ["environment"] = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "production",
        ["version"] = Environment.GetEnvironmentVariable("APP_VERSION") ?? "1.0.0"
    }
);

var app = builder.Build();

// Add correlation ID middleware
app.Use(async (context, next) =>
{
    var correlationId = context.Request.Headers["X-Correlation-ID"].FirstOrDefault() ?? Guid.NewGuid().ToString();
    context.Response.Headers.Add("X-Correlation-ID", correlationId);
    
    using (Log.Logger.ForContext("CorrelationId", correlationId)
                     .ForContext("TraceId", Activity.Current?.TraceId.ToString())
                     .ForContext("SpanId", Activity.Current?.SpanId.ToString()))
    {
        await next();
    }
});

app.MapGet("/", () =>
{
    Log.Information("Root endpoint accessed");
    return "Hello from GitOps Sample App with Observability!";
});

app.MapGet("/health", () =>
{
    Log.Information("Health check endpoint accessed");
    return Results.Ok(new
    {
        status = "healthy",
        timestamp = DateTime.UtcNow,
        version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "1.0.0"
    });
});

app.MapGet("/slow", async () =>
{
    Log.Information("Slow endpoint accessed - simulating delay");
    await Task.Delay(Random.Shared.Next(500, 2000));
    return Results.Ok(new { message = "Slow operation completed" });
});

app.MapGet("/error", () =>
{
    Log.Error("Error endpoint accessed - throwing exception");
    throw new Exception("Simulated error for testing");
});

try
{
    Log.Information("Starting Sample App");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
