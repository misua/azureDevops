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

// In-memory data stores
var users = new List<User>
{
    new User { Id = 1, Name = "Alice Johnson", Email = "alice@example.com" },
    new User { Id = 2, Name = "Bob Smith", Email = "bob@example.com" },
    new User { Id = 3, Name = "Carol Williams", Email = "carol@example.com" }
};

var products = new List<Product>
{
    new Product { Id = 1, Name = "Laptop", Price = 999.99m, Stock = 50 },
    new Product { Id = 2, Name = "Mouse", Price = 29.99m, Stock = 200 },
    new Product { Id = 3, Name = "Keyboard", Price = 79.99m, Stock = 150 },
    new Product { Id = 4, Name = "Monitor", Price = 299.99m, Stock = 75 }
};

var orders = new List<Order>();
int orderIdCounter = 1;

// Root endpoint
app.MapGet("/", () =>
{
    Log.Information("Root endpoint accessed");
    return Results.Ok(new
    {
        message = "GitOps Sample App with Observability",
        version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "1.0.0",
        endpoints = new[]
        {
            "GET /health - Health check",
            "GET /api/users - List all users",
            "GET /api/users/{id} - Get user by ID",
            "POST /api/users - Create new user",
            "GET /api/products - List all products",
            "GET /api/products?search={term} - Search products",
            "GET /api/products/{id} - Get product by ID",
            "POST /api/orders - Create new order",
            "GET /api/orders - List all orders",
            "GET /api/slow - Simulate slow request",
            "GET /api/error - Simulate error"
        }
    });
});

// Health check endpoint
app.MapGet("/health", () =>
{
    Log.Information("Health check endpoint accessed");
    return Results.Ok(new
    {
        status = "healthy",
        timestamp = DateTime.UtcNow,
        version = Environment.GetEnvironmentVariable("APP_VERSION") ?? "1.0.0",
        dependencies = new
        {
            database = "healthy",
            cache = "healthy"
        }
    });
});

// Users API
app.MapGet("/api/users", () =>
{
    Log.Information("Fetching all users, count: {Count}", users.Count);
    return Results.Ok(users);
});

app.MapGet("/api/users/{id:int}", (int id) =>
{
    Log.Information("Fetching user with ID: {UserId}", id);
    var user = users.FirstOrDefault(u => u.Id == id);
    if (user == null)
    {
        Log.Warning("User not found: {UserId}", id);
        return Results.NotFound(new { error = "User not found" });
    }
    return Results.Ok(user);
});

app.MapPost("/api/users", (User newUser) =>
{
    newUser.Id = users.Max(u => u.Id) + 1;
    users.Add(newUser);
    Log.Information("Created new user: {UserId} - {UserName}", newUser.Id, newUser.Name);
    return Results.Created($"/api/users/{newUser.Id}", newUser);
});

// Products API
app.MapGet("/api/products", (string? search) =>
{
    if (!string.IsNullOrEmpty(search))
    {
        Log.Information("Searching products with term: {SearchTerm}", search);
        var results = products.Where(p => p.Name.Contains(search, StringComparison.OrdinalIgnoreCase)).ToList();
        return Results.Ok(results);
    }
    
    Log.Information("Fetching all products, count: {Count}", products.Count);
    return Results.Ok(products);
});

app.MapGet("/api/products/{id:int}", (int id) =>
{
    Log.Information("Fetching product with ID: {ProductId}", id);
    var product = products.FirstOrDefault(p => p.Id == id);
    if (product == null)
    {
        Log.Warning("Product not found: {ProductId}", id);
        return Results.NotFound(new { error = "Product not found" });
    }
    return Results.Ok(product);
});

// Orders API
app.MapGet("/api/orders", () =>
{
    Log.Information("Fetching all orders, count: {Count}", orders.Count);
    return Results.Ok(orders);
});

app.MapPost("/api/orders", async (OrderRequest orderRequest) =>
{
    using var activity = Activity.Current?.Source.StartActivity("ProcessOrder");
    activity?.SetTag("order.user_id", orderRequest.UserId);
    activity?.SetTag("order.product_id", orderRequest.ProductId);
    
    Log.Information("Processing order for User: {UserId}, Product: {ProductId}, Quantity: {Quantity}",
        orderRequest.UserId, orderRequest.ProductId, orderRequest.Quantity);
    
    // Simulate order validation
    await Task.Delay(Random.Shared.Next(50, 150));
    
    var user = users.FirstOrDefault(u => u.Id == orderRequest.UserId);
    if (user == null)
    {
        Log.Warning("Order failed: User not found - {UserId}", orderRequest.UserId);
        return Results.BadRequest(new { error = "User not found" });
    }
    
    var product = products.FirstOrDefault(p => p.Id == orderRequest.ProductId);
    if (product == null)
    {
        Log.Warning("Order failed: Product not found - {ProductId}", orderRequest.ProductId);
        return Results.BadRequest(new { error = "Product not found" });
    }
    
    if (product.Stock < orderRequest.Quantity)
    {
        Log.Warning("Order failed: Insufficient stock for Product: {ProductId}, Requested: {Quantity}, Available: {Stock}",
            orderRequest.ProductId, orderRequest.Quantity, product.Stock);
        return Results.BadRequest(new { error = "Insufficient stock" });
    }
    
    // Create order
    var order = new Order
    {
        Id = orderIdCounter++,
        UserId = orderRequest.UserId,
        UserName = user.Name,
        ProductId = orderRequest.ProductId,
        ProductName = product.Name,
        Quantity = orderRequest.Quantity,
        TotalPrice = product.Price * orderRequest.Quantity,
        OrderDate = DateTime.UtcNow,
        Status = "Confirmed"
    };
    
    // Update stock
    product.Stock -= orderRequest.Quantity;
    orders.Add(order);
    
    Log.Information("Order created successfully: {OrderId}, Total: {TotalPrice:C}", order.Id, order.TotalPrice);
    
    return Results.Created($"/api/orders/{order.Id}", order);
});

// Slow endpoint for latency testing
app.MapGet("/api/slow", async () =>
{
    var delay = Random.Shared.Next(2000, 5000);
    Log.Information("Slow endpoint accessed - simulating {Delay}ms delay", delay);
    await Task.Delay(delay);
    return Results.Ok(new { message = "Slow operation completed", delayMs = delay });
});

// Error endpoint for testing alerts
app.MapGet("/api/error", () =>
{
    Log.Error("Error endpoint accessed - throwing exception");
    throw new Exception("Simulated error for testing observability alerts");
});

// Records for data models
record User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
}

record Product
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public int Stock { get; set; }
}

record Order
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public int ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public decimal TotalPrice { get; set; }
    public DateTime OrderDate { get; set; }
    public string Status { get; set; } = string.Empty;
}

record OrderRequest
{
    public int UserId { get; set; }
    public int ProductId { get; set; }
    public int Quantity { get; set; }
}

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
