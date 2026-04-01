import { tool } from "@opencode-ai/plugin"

interface FigmaConfig {
  token: string
  apiUrl: string
}

function getFigmaConfig(): FigmaConfig {
  const token = process.env.FIGMA_PERSONAL_TOKEN
  if (!token) {
    throw new Error(
      "FIGMA_PERSONAL_TOKEN environment variable is not set. " +
      "Generate a token at: https://www.figma.com/developers/api#access-tokens"
    )
  }
  
  return {
    token,
    apiUrl: "https://api.figma.com"
  }
}

export const get_file = tool({
  description: "Get a Figma file by key. Returns the complete file structure including all nodes, components, and styles.",
  args: {
    file_key: tool.schema.string().describe("The Figma file key (extracted from URL: figma.com/file/FILE_KEY/...)"),
    depth: tool.schema.number().describe("Depth of nodes to return (0 = no children, 1 = top-level children, etc.)").optional().default(1),
  },
  async execute(args) {
    const config = getFigmaConfig()
    
    const url = `${config.apiUrl}/v1/files/${args.file_key}?depth=${args.depth}`
    
    const response = await fetch(url, {
      headers: {
        "X-Figma-Token": config.token,
        "Accept": "application/json"
      }
    })
    
    if (!response.ok) {
      throw new Error(`Figma API error: ${response.status} ${response.statusText}`)
    }
    
    const data = await response.json()
    
    return {
      name: data.name,
      lastModified: data.lastModified,
      thumbnailUrl: data.thumbnailUrl,
      nodes: Object.keys(data.nodes).map(key => ({
        id: key,
        name: data.nodes[key].name,
        type: data.nodes[key].type
      }))
    }
  }
})

export const get_node = tool({
  description: "Get a specific node from a Figma file. Returns detailed node structure including children, styles, and properties.",
  args: {
    file_key: tool.schema.string().describe("The Figma file key"),
    node_id: tool.schema.string().describe("The node ID (e.g., '123-456' from URL parameter ?node-id=123-456)"),
  },
  async execute(args) {
    const config = getFigmaConfig()
    
    const url = `${config.apiUrl}/v1/files/${args.file_key}/nodes?ids=${args.node_id}`
    
    const response = await fetch(url, {
      headers: {
        "X-Figma-Token": config.token,
        "Accept": "application/json"
      }
    })
    
    if (!response.ok) {
      throw new Error(`Figma API error: ${response.status} ${response.statusText}`)
    }
    
    const data = await response.json()
    const node = data.nodes[args.node_id]
    
    if (!node) {
      throw new Error(`Node ${args.node_id} not found in file ${args.file_key}`)
    }
    
    return {
      id: node.id,
      name: node.name,
      type: node.type,
      visible: node.visible,
      bounds: node.bounds,
      fills: node.fills,
      strokes: node.strokes,
      style: node.style,
      children: node.children?.map((child: any) => ({
        id: child.id,
        name: child.name,
        type: child.type
      }))
    }
  }
})

export const get_image = tool({
  description: "Get image URL for a Figma node. Returns a temporary URL that can be used to download the rendered image.",
  args: {
    file_key: tool.schema.string().describe("The Figma file key"),
    node_id: tool.schema.string().describe("The node ID to render"),
    scale: tool.schema.number().describe("Image scale (1, 2, 3, or 4)").optional().default(2),
    format: tool.schema.string().describe("Image format (png, jpg, svg, webp)").optional().default("png"),
  },
  async execute(args) {
    const config = getFigmaConfig()
    
    const url = `${config.apiUrl}/v1/images/${args.file_key}?ids=${args.node_id}&scale=${args.scale}&format=${args.format}`
    
    const response = await fetch(url, {
      headers: {
        "X-Figma-Token": config.token,
        "Accept": "application/json"
      }
    })
    
    if (!response.ok) {
      throw new Error(`Figma API error: ${response.status} ${response.statusText}`)
    }
    
    const data = await response.json()
    return {
      nodeId: args.node_id,
      imageUrl: data.images[args.node_id],
      scale: args.scale,
      format: args.format
    }
  }
})

export const get_variables = tool({
  description: "Get design variables (tokens) from a Figma file. Returns colors, spacing, typography, and other design tokens.",
  args: {
    file_key: tool.schema.string().describe("The Figma file key"),
  },
  async execute(args) {
    const config = getFigmaConfig()
    
    const url = `${config.apiUrl}/v1/files/${args.file_key}/variables/local`
    
    const response = await fetch(url, {
      headers: {
        "X-Figma-Token": config.token,
        "Accept": "application/json"
      }
    })
    
    if (!response.ok) {
      throw new Error(`Figma API error: ${response.status} ${response.statusText}`)
    }
    
    const data = await response.json()
    
    return {
      variableCollections: data.meta.variableCollections.map((collection: any) => ({
        id: collection.id,
        name: collection.name,
        variables: collection.variableIds.map((id: string) => {
          const variable = data.meta.variables[id]
          return {
            id: variable.id,
            name: variable.name,
            type: variable.resolvedType,
            values: Object.entries(variable.valuesByMode).map(([modeId, value]) => ({
              modeId,
              value
            }))
          }
        })
      }))
    }
  }
})

export const get_comments = tool({
  description: "Get comments from a Figma file. Returns all comments with their positions on the canvas.",
  args: {
    file_key: tool.schema.string().describe("The Figma file key"),
  },
  async execute(args) {
    const config = getFigmaConfig()
    
    const url = `${config.apiUrl}/v1/files/${args.file_key}/comments`
    
    const response = await fetch(url, {
      headers: {
        "X-Figma-Token": config.token,
        "Accept": "application/json"
      }
    })
    
    if (!response.ok) {
      throw new Error(`Figma API error: ${response.status} ${response.statusText}`)
    }
    
    const data = await response.json()
    
    return {
      comments: data.comments.map((comment: any) => ({
        id: comment.id,
        fileKey: comment.fileKey,
        parent: comment.parent,
        author: {
          handle: comment.author.handle,
          imgUrl: comment.author.imgUrl
        },
        body: comment.body,
        createdAt: comment.createdAt,
        resolved: comment.resolved
      }))
    }
  }
})
