from flask import Flask
import requests
import os

app = Flask(__name__)


def get_az():
    metadata_url = os.environ.get("ECS_CONTAINER_METADATA_URI_V4")
    if metadata_url:
        try:
            response = requests.get(f"{metadata_url}/task")
            data = response.json()
            return data.get("AvailabilityZone", "Unknown AZ")
        except Exception as e:
            return f"Error fetching AZ: {str(e)}"
    return "Not running in ECS (Local/Cloud9)"


@app.route("/")
def hello():
    az = get_az()
    return f"""
    <h1>Hello from ECS Demo App!</h1>
    <p><b>Current Availability Zone:</b> {az}</p>
    <p>Refresh the page to see if the Load Balancer switches you to another zone!</p>
    """


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
