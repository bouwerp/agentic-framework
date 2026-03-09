import { tool } from "@opencode-ai/plugin"
import * as crypto from "crypto"

interface OAuthConfig {
  clientId: string
  redirectUri: string
  authorizationEndpoint: string
  tokenEndpoint: string
  registrationEndpoint: string
}

const FIGMA_OAUTH_CONFIG: OAuthConfig = {
  clientId: "figma-mcp-opencode",  // Dynamic registration will be used
  redirectUri: "http://localhost:8080/callback",
  authorizationEndpoint: "https://www.figma.com/oauth/mcp",
  tokenEndpoint: "https://api.figma.com/v1/oauth/token",
  registrationEndpoint: "https://api.figma.com/v1/oauth/mcp/register"
}

export const figma_oauth_url = tool({
  description: "Generate a Figma OAuth authorization URL for manual authentication. Use this in headless environments where automatic browser opening is not available. Copy the generated URL to your browser, authorize, and you'll get an authorization code that can be exchanged for tokens.",
  args: {
    state: tool.schema.string().describe("Random state parameter for security (auto-generated if not provided)").optional(),
  },
  async execute(args) {
    const state = args.state || crypto.randomBytes(16).toString('hex')
    const codeVerifier = crypto.randomBytes(32).toString('base64url')
    const codeChallenge = crypto
      .createHash('sha256')
      .update(codeVerifier)
      .digest('base64url')
    
    const params = new URLSearchParams({
      client_id: 'figma-mcp-opencode',
      redirect_uri: FIGMA_OAUTH_CONFIG.redirectUri,
      response_type: 'code',
      scope: 'mcp:connect',
      state: state,
      code_challenge: codeChallenge,
      code_challenge_method: 'S256'
    })
    
    const authUrl = `${FIGMA_OAUTH_CONFIG.authorizationEndpoint}?${params.toString()}`
    
    return {
      authorizationUrl: authUrl,
      state: state,
      codeVerifier: codeVerifier,
      instructions: [
        "1. Copy the authorizationUrl and open it in your browser",
        "2. Authorize the Figma MCP application",
        "3. You will be redirected to a URL with a 'code' parameter",
        "4. Copy the authorization code from the URL",
        "5. Use the figma_oauth_token tool with the code and codeVerifier to exchange for tokens",
        "",
        "Note: The redirect will likely fail (localhost not running), but the code will be in the URL"
      ]
    }
  }
})

export const figma_oauth_token = tool({
  description: "Exchange a Figma OAuth authorization code for access and refresh tokens. Use this after obtaining an authorization code from the OAuth flow.",
  args: {
    code: tool.schema.string().describe("Authorization code from the OAuth callback URL"),
    codeVerifier: tool.schema.string().describe("Code verifier used in the PKCE flow"),
    redirectUri: tool.schema.string().describe("Redirect URI used in the authorization request").optional().default("http://localhost:8080/callback"),
  },
  async execute(args) {
    const tokenResponse = await fetch(FIGMA_OAUTH_CONFIG.tokenEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code: args.code,
        redirect_uri: args.redirectUri,
        code_verifier: args.codeVerifier
      })
    })
    
    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      throw new Error(`Token exchange failed: ${tokenResponse.status} ${error}`)
    }
    
    const tokens = await tokenResponse.json()
    
    return {
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token,
      expiresIn: tokens.expires_in,
      scope: tokens.scope,
      tokenType: tokens.token_type,
      instructions: [
        "Store these tokens securely. The access token can be used in the Authorization header:",
        `Authorization: Bearer ${tokens.access_token}`,
        "",
        "The refresh token can be used to obtain new access tokens when they expire."
      ]
    }
  }
})

export const figma_oauth_refresh = tool({
  description: "Refresh an expired Figma OAuth access token using a refresh token.",
  args: {
    refreshToken: tool.schema.string().describe("Refresh token from the previous OAuth response"),
  },
  async execute(args) {
    const tokenResponse = await fetch(FIGMA_OAUTH_CONFIG.tokenEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: args.refreshToken
      })
    })
    
    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      throw new Error(`Token refresh failed: ${tokenResponse.status} ${error}`)
    }
    
    const tokens = await tokenResponse.json()
    
    return {
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token || args.refreshToken,
      expiresIn: tokens.expires_in,
      scope: tokens.scope,
      tokenType: tokens.token_type
    }
  }
})

export const figma_whoami = tool({
  description: "Get the current authenticated user's information from Figma. Use this to verify OAuth tokens are working.",
  args: {
    accessToken: tool.schema.string().describe("Figma OAuth access token"),
  },
  async execute(args) {
    const response = await fetch('https://api.figma.com/v1/me', {
      headers: {
        'Authorization': `Bearer ${args.accessToken}`
      }
    })
    
    if (!response.ok) {
      const error = await response.text()
      throw new Error(`API call failed: ${response.status} ${error}`)
    }
    
    const user = await response.json()
    
    return {
      userId: user.id,
      handle: user.handle,
      email: user.email,
      imgUrl: user.img_url,
      planType: user.plan_type
    }
  }
})
