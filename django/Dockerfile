# Use Python 3.11 slim image
FROM python:3.11-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Set work directory
WORKDIR /app

# Install system dependencies
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client \
        build-essential \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . /app/

# Create staticfiles and media directories
RUN mkdir -p /app/staticfiles /app/media

# Expose port
EXPOSE 8010

# Health check
# HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
#     CMD python -c "import requests; requests.get('http://localhost:8010/admin/', timeout=10)"

# Copy and make start script executable
COPY start.sh /app/
RUN chmod +x /app/start.sh

# Default command (can be overridden by docker-compose)
CMD ["./start.sh"]