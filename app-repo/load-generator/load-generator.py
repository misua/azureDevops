#!/usr/bin/env python3
"""
Load Generator for GitOps Sample App
Generates realistic traffic patterns to demonstrate observability features
"""

import requests
import time
import random
import json
import sys
from datetime import datetime
from typing import Dict, List

# Configuration
APP_URL = "http://sample-app.default.svc.cluster.local"
SCENARIOS = {
    "normal": {"weight": 70, "error_rate": 0.02},
    "spike": {"weight": 20, "error_rate": 0.05},
    "error": {"weight": 10, "error_rate": 0.30}
}

class LoadGenerator:
    def __init__(self, base_url: str):
        self.base_url = base_url
        self.session = requests.Session()
        self.stats = {
            "total_requests": 0,
            "successful_requests": 0,
            "failed_requests": 0,
            "slow_requests": 0
        }
    
    def log(self, message: str, level: str = "INFO"):
        timestamp = datetime.utcnow().isoformat()
        print(f"{timestamp} [{level}] {message}", flush=True)
    
    def make_request(self, method: str, endpoint: str, **kwargs) -> Dict:
        """Make HTTP request with timing and error handling"""
        start_time = time.time()
        correlation_id = f"load-gen-{int(time.time() * 1000)}-{random.randint(1000, 9999)}"
        
        headers = kwargs.get("headers", {})
        headers["X-Correlation-ID"] = correlation_id
        kwargs["headers"] = headers
        
        try:
            response = self.session.request(method, f"{self.base_url}{endpoint}", **kwargs)
            duration = time.time() - start_time
            
            self.stats["total_requests"] += 1
            
            if response.status_code < 400:
                self.stats["successful_requests"] += 1
                if duration > 2.0:
                    self.stats["slow_requests"] += 1
                    self.log(f"SLOW: {method} {endpoint} - {duration:.2f}s", "WARN")
            else:
                self.stats["failed_requests"] += 1
                self.log(f"ERROR: {method} {endpoint} - {response.status_code}", "ERROR")
            
            return {
                "status_code": response.status_code,
                "duration": duration,
                "correlation_id": correlation_id
            }
        except Exception as e:
            self.stats["total_requests"] += 1
            self.stats["failed_requests"] += 1
            self.log(f"EXCEPTION: {method} {endpoint} - {str(e)}", "ERROR")
            return {
                "status_code": 0,
                "duration": time.time() - start_time,
                "error": str(e)
            }
    
    def browse_products(self):
        """Simulate user browsing products"""
        # List all products
        self.make_request("GET", "/api/products")
        time.sleep(random.uniform(0.1, 0.5))
        
        # Search for specific product
        search_terms = ["Laptop", "Mouse", "Keyboard", "Monitor"]
        self.make_request("GET", f"/api/products?search={random.choice(search_terms)}")
        time.sleep(random.uniform(0.1, 0.5))
        
        # View specific product
        product_id = random.randint(1, 4)
        self.make_request("GET", f"/api/products/{product_id}")
    
    def create_order(self, should_fail: bool = False):
        """Simulate order creation"""
        # Get users first
        self.make_request("GET", "/api/users")
        time.sleep(random.uniform(0.1, 0.3))
        
        # Create order
        user_id = random.randint(1, 3)
        product_id = random.randint(1, 4)
        quantity = random.randint(1, 5)
        
        if should_fail:
            # Intentionally create failing order
            quantity = 1000  # Too much stock
        
        order_data = {
            "userId": user_id,
            "productId": product_id,
            "quantity": quantity
        }
        
        self.make_request("POST", "/api/orders", json=order_data)
    
    def check_health(self):
        """Health check"""
        self.make_request("GET", "/health")
    
    def trigger_slow_request(self):
        """Trigger intentionally slow endpoint"""
        self.make_request("GET", "/api/slow")
    
    def trigger_error(self):
        """Trigger error endpoint"""
        try:
            self.make_request("GET", "/api/error")
        except:
            pass  # Expected to fail
    
    def normal_traffic(self):
        """Generate normal traffic pattern"""
        actions = [
            (self.check_health, 10),
            (self.browse_products, 40),
            (lambda: self.create_order(False), 30),
            (self.make_request, 20, "GET", "/")
        ]
        
        action = random.choices(
            [a[0] for a in actions],
            weights=[a[1] for a in actions]
        )[0]
        
        if action == self.make_request:
            action("GET", "/")
        else:
            action()
    
    def spike_traffic(self):
        """Generate traffic spike"""
        for _ in range(random.randint(5, 15)):
            self.browse_products()
            time.sleep(random.uniform(0.05, 0.1))
    
    def error_traffic(self):
        """Generate traffic with errors"""
        if random.random() < 0.5:
            self.trigger_error()
        else:
            self.create_order(should_fail=True)
    
    def run(self, duration_seconds: int = 3600):
        """Run load generator"""
        self.log(f"Starting load generator for {duration_seconds}s")
        self.log(f"Target: {self.base_url}")
        
        start_time = time.time()
        iteration = 0
        
        try:
            while time.time() - start_time < duration_seconds:
                iteration += 1
                
                # Select scenario based on weights
                scenario = random.choices(
                    list(SCENARIOS.keys()),
                    weights=[s["weight"] for s in SCENARIOS.values()]
                )[0]
                
                # Execute scenario
                if scenario == "normal":
                    self.normal_traffic()
                    time.sleep(random.uniform(1, 3))
                elif scenario == "spike":
                    self.spike_traffic()
                    time.sleep(random.uniform(0.5, 1))
                elif scenario == "error":
                    self.error_traffic()
                    time.sleep(random.uniform(1, 2))
                
                # Log stats every 100 iterations
                if iteration % 100 == 0:
                    self.print_stats()
        
        except KeyboardInterrupt:
            self.log("Stopping load generator...")
        
        finally:
            self.print_stats()
            self.log("Load generator stopped")
    
    def print_stats(self):
        """Print current statistics"""
        total = self.stats["total_requests"]
        if total == 0:
            return
        
        success_rate = (self.stats["successful_requests"] / total) * 100
        error_rate = (self.stats["failed_requests"] / total) * 100
        slow_rate = (self.stats["slow_requests"] / total) * 100
        
        self.log(
            f"Stats: Total={total}, Success={success_rate:.1f}%, "
            f"Errors={error_rate:.1f}%, Slow={slow_rate:.1f}%"
        )

def main():
    # Get configuration from environment or use defaults
    import os
    app_url = os.getenv("APP_URL", APP_URL)
    duration = int(os.getenv("DURATION_SECONDS", "3600"))
    
    generator = LoadGenerator(app_url)
    generator.run(duration)

if __name__ == "__main__":
    main()
