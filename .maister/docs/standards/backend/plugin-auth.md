## Plugin Authentication

### Browser SDK Auth

Plugin iframes use `sdk.hostApp.getToken()` to obtain the logged-in user's JWT from the host via postMessage. The host's `PluginMessageHandler` handles the `getToken` message by reading from localStorage.

### Plugin Server-Side Auth

Plugin backends (e.g., Next.js API routes) receive the JWT from their own frontend and forward it to the host API via `createServerSDK`:

```typescript
// Plugin API route — pass the incoming request directly
const sdk = createServerSDK("my-plugin", undefined, req);
```

The SDK extracts the `Authorization` header from the request object automatically.

### Permission Checking in Plugins

Plugins should check user permissions before showing write UI. Decode the JWT from `hostApp.getToken()` to read the `permissions` claim:

```typescript
const token = await sdk.hostApp.getToken();
if (token) {
  const payload = JSON.parse(atob(token.split(".")[1]));
  const canEdit = payload.permissions?.includes("EDIT");
}
```
