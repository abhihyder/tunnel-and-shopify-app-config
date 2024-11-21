# Cloudflare Tunnel and Shopify App Configuration Script

This script automates the process of starting a Cloudflare tunnel, capturing its generated URL, and updating the necessary configuration files for a Shopify app. It also deploys the Shopify app after updating the configurations.

## **Features**
- Starts a Cloudflare tunnel and extracts the generated URL.
- Updates the following files with the new URL:
  - `.env`: Updates `APP_URL`.
  - `../web/.env`: Updates `VITE_BASE_URL`.
  - `shopify.app.toml`: Updates `application_url`, `redirect_urls`, `client_id`, and `scopes`.
- Verifies the presence of required environment variables.
- Includes a timeout mechanism to handle delayed tunnel startup.
- Deploys the Shopify app after successful updates.

---

## **Usage Instructions**

### **1. Prerequisites**
- Ensure you have the following installed:
  - [Cloudflare Tunnel (cloudflared)](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation)
  - Shopify CLI
- A properly configured `.env` file with the following variables:
  ```plaintext
  SHOPIFY_API_KEY=<your_shopify_api_key>
  SHOPIFY_API_SCOPES=<your_shopify_api_scopes>
  ```
- Place the script in the root directory of your Shopify app.

---

### **2. Create the `shopify.app.toml` File**
Before running the script, you'll need the `shopify.app.toml` file, which contains your app's configuration. If you don't have it yet, you can create it using the Shopify CLI.

To generate the `shopify.app.toml` file, run the following command:
```bash
shopify app config link
```

This command will automatically create the `shopify.app.toml` file with the necessary configuration for your Shopify app.

**Important:**  
You should **never** commit the `shopify.app.toml` file to your Git repository. This file contains sensitive app configuration and is specific to your development environment. Add it to your `.gitignore` file to prevent it from being tracked by version control.

To do this, add the following line to your `.gitignore`:
```plaintext
shopify.app.toml
```

---

### **3. Create the `tunnel.sh` Script File**
Create a new file called `tunnel.sh` in the root directory of your project. This script will automate the Cloudflare tunnel process and configuration updates.

1. In the root directory of your Shopify app, create the `tunnel.sh` file:
   ```bash
   touch tunnel.sh
   ```

2. Copy the script content (provided below) into the `tunnel.sh` file.

3. Make the script executable:
   ```bash
   chmod +x tunnel.sh
   ```

---

### **4. Running the Script**
Execute the script:
```bash
./tunnel.sh
```

**Note:**  
- **Do not run this script when preparing your app for public subscription.** This script is intended for local development environments only and should not be executed in production or public-facing apps.
- The Cloudflare tunnel is designed for testing and development purposes, and running it in a live environment may expose your app to unnecessary risks.

---

### **5. Script Workflow**
1. Loads environment variables from the `.env` file.
2. Verifies the presence of `SHOPIFY_API_KEY` and `SHOPIFY_API_SCOPES`.
3. Starts the Cloudflare tunnel and waits for the generated URL, with a maximum wait time of 60 seconds.
4. Updates the following files:
   - `.env`: Sets `APP_URL` to the new Cloudflare tunnel URL.
   - `../web/.env`: Sets `VITE_BASE_URL` to the new Cloudflare tunnel URL.
   - `shopify.app.toml`: Updates:
     - `application_url` to `<TUNNEL_URL>/back/home`.
     - `redirect_urls` to `<TUNNEL_URL>/back/authenticate`.
     - `client_id` to the value of `SHOPIFY_API_KEY` from `.env`.
     - `scopes` to the value of `SHOPIFY_API_SCOPES` from `.env`.
5. Deploys the Shopify app using the `shopify app deploy` command.
6. Cleans up the temporary log file (`tunnel.log`).

---

### **6. Troubleshooting**
- **`.env file not found! Exiting.`**  
  Ensure your `.env` file is in the correct directory and contains the required variables.

- **`Failed to retrieve Cloudflare URL within 60 seconds.`**  
  Increase the `MAX_WAIT` time in the script if the tunnel takes longer to initialize.

- **Other Issues**: Check the `tunnel.log` file for errors related to the Cloudflare tunnel.

---

### **7. Example .env File**
```plaintext
APP_URL=https://your-previous-url
SHOPIFY_API_KEY=your-shopify-api-key
SHOPIFY_API_SCOPES=read_products,write_products,read_orders
```
Here's the updated **Customization** section with similar notes for all the relevant `sed` commands:

---

### **8. Customization**
You can customize the `sed` commands used in the `tunnel.sh` file based on your app's specific configuration needs:

- The following line starts the Cloudflare tunnel, forwarding traffic to your app's local server:
  ```bash
  cloudflared tunnel --url http://localhost:8000 > tunnel.log 2>&1 &
  ```

  **Note:** If your app is running on a different port, ensure that you adjust the port number accordingly (e.g., `http://localhost:3000, http://localhost:5000`). Replace `8000` with your app's correct port.

- The following line updates the `APP_URL` in the `.env` file with the new Cloudflare tunnel URL:
  ```bash
  sed -i "s|^APP_URL=.*|APP_URL=$TUNNEL_URL|" $APP_ENV_FILE
  ```

  **Note:** Your `APP_URL` might include a different path or subdomain, depending on your app's setup. Make sure to adjust the pattern if necessary (e.g., `https://yourapp.com`, `https://app.yoursite.com`, etc.).

- To update the `VITE_BASE_URL` in the `../web/.env` file, use this command:
  ```bash
  sed -i "s|^VITE_BASE_URL=.*|VITE_BASE_URL= \"$TUNNEL_URL/back\"|" $WEB_ENV_FILE
  ```

  **Note:** Your `VITE_BASE_URL` could be something different, such as `/back/api` or any other custom path based on your app's configuration. Ensure you adjust the URL pattern accordingly.

- The `application_url` in the `shopify.app.toml` file can be updated with the following command:
  ```bash
  sed -i "s|^application_url = \".*\"|application_url = \"$TUNNEL_URL/back/home\"|" $CONFIG_FILE
  ```

  **Note:** Your `application_url` might have a different path, depending on your app's routes and structure. Adjust the URL to match your app's specific endpoint (e.g., `/home`, `/dashboard`, `/admin`).

- To replace the `redirect_urls` in `shopify.app.toml`:
  ```bash
  sed -i "s|^  \"https://.*\"|  \"$TUNNEL_URL/back/authenticate\"|" $CONFIG_FILE
  ```

  **Note:** Similarly, your `redirect_urls` could differ depending on the authentication flow or other custom routes in your app. Ensure that the path corresponds to your app's specific setup (e.g., `/authenticate`, `/auth/callback`, `/login`).

These `sed` commands can be adjusted to suit your app's specific configuration requirements. If your app has different routes or environment variables, simply modify the patterns within these commands accordingly.

---

### **9. Important Notes**
- Ensure all paths are correct, especially for `.env`, `../web/.env`, and `shopify.app.toml`.
- **Do not run this script in a production environment** or when preparing your app for public subscription. It is meant for local development only.
- Test the script in a development environment before deploying to production.

---



## List All Cloudflare Tunnel Processes
To check how many Cloudflare tunnels are currently running on your system, you can use a combination of `ps` or `pgrep` commands to search for `cloudflared` processes. Here’s how:
```bash
ps aux | grep cloudflared | grep -v grep
```

This command:
- Lists all processes (`ps aux`).
- Filters for processes containing the word `cloudflared`.
- Excludes the `grep` process itself from the results (`grep -v grep`).

This command lists all active tunnels, their states, and other details (e.g., name, uptime, and connection status).

### Example Outputs:
   ```
   user      12345  0.0  0.1 123456  5678 ?        Ssl  12:00   0:00 cloudflared tunnel --url http://localhost:8006
   user      12346  0.0  0.1 123456  5678 ?        Ssl  12:00   0:00 cloudflared tunnel --url http://localhost:3000
   ```
   Two Cloudflare tunnels are running.


**Note**:
 If you suspect unused tunnels, you can terminate them using `pkill cloudflared` or by stopping specific processes using their PID (`kill <PID>`).

## Terminate Tunnels

To terminate Cloudflare tunnels, you can choose to stop all of them at once or terminate them one by one. Below are the steps for both approaches:


### **Option 1: Terminate All Tunnels at Once**
You can use the `pkill` command to stop all `cloudflared` processes at once:

```bash
pkill cloudflared
```

This command will kill all running instances of `cloudflared`. It is straightforward but does not provide a way to target specific tunnels.


### **Option 2: Terminate Tunnels One by One**
If you want more control and wish to terminate tunnels individually:

#### 1. **List All Running Tunnels**
Use the `ps` command to identify each tunnel process:

```bash
ps aux | grep cloudflared | grep -v grep
```

Example Output:
```
user      12345  0.0  0.1 123456  5678 ?        Ssl  12:00   0:00 cloudflared tunnel --url http://localhost:8006
user      12346  0.0  0.1 123456  5678 ?        Ssl  12:00   0:00 cloudflared tunnel --url http://localhost:3000
```

The first column is the username, and the second column (e.g., `12345`, `12346`) is the process ID (PID).

#### 2. **Terminate a Specific Tunnel**
Use the `kill` command followed by the PID to terminate a specific tunnel:

```bash
kill <PID>
```

For example:
```bash
kill 12345
```

To forcefully terminate it (if the tunnel does not stop gracefully):
```bash
kill -9 <PID>
```

### Summary:
- Use `pkill` to terminate all tunnels at once.
- Use `kill <PID>` for granular control to terminate one by one.
