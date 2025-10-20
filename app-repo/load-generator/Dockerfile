FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir requests

# Copy load generator script
COPY load-generator.py .

# Make script executable
RUN chmod +x load-generator.py

# Run load generator
CMD ["python", "load-generator.py"]
