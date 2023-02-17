using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class RenderToTexture : ScriptableRendererFeature {

    class RenderToTexturePass : ScriptableRenderPass {
    private RenderTargetHandle destination;
    private Material material;
    private FilteringSettings filteringSettings;
    private ShaderTagId shaderTagId;
    private string cmdName;
    private string textureName;
    private new Color clearColor;

    public RenderToTexturePass(RenderToTexture.Settings param) {
        this.filteringSettings = new FilteringSettings(RenderQueueRange.all, param.layerMask);
        this.material = param.material;
        this.shaderTagId = new ShaderTagId(param.passName);
        this.cmdName = param.cmdName;
        this.textureName = param.textureName;
        this.clearColor = param.clearColor;
    }

    public void Setup(RenderTargetHandle destination) {
        this.destination = destination;
    }
    
    public override void Configure(CommandBuffer cmd, RenderTextureDescriptor cameraTextureDescriptor) {
        RenderTextureDescriptor descriptor = cameraTextureDescriptor;
        descriptor.msaaSamples = 1;

        cmd.GetTemporaryRT(this.destination.id, descriptor, FilterMode.Point);
        this.ConfigureTarget(this.destination.Identifier());
        this.ConfigureClear(ClearFlag.All, this.clearColor);
    }
    
    public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {
        CommandBuffer cmd = CommandBufferPool.Get(this.cmdName);
        context.ExecuteCommandBuffer(cmd);
        cmd.Clear();

        var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
        var drawSettings = this.CreateDrawingSettings(this.shaderTagId, ref renderingData, sortFlags);
        
        ref CameraData cameraData = ref renderingData.cameraData;
        Camera camera = cameraData.camera;

        if (cameraData.isStereoEnabled) {
            context.StartMultiEye(camera);
        }

        drawSettings.overrideMaterial = this.material;
        context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref this.filteringSettings);
        
        cmd.SetGlobalTexture(this.textureName, this.destination.id);
        context.ExecuteCommandBuffer(cmd);

        CommandBufferPool.Release(cmd);
    }
    
    public override void FrameCleanup(CommandBuffer cmd) {
        if (this.destination != RenderTargetHandle.CameraTarget) {
            cmd.ReleaseTemporaryRT(this.destination.id);
            this.destination = RenderTargetHandle.CameraTarget;
        }
    }
}
    
    [System.Serializable]
    public class Settings {
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingPrePasses;
        public LayerMask layerMask = -1;
        public Material material;
        public string passName;
        public string cmdName;
        public string textureName;
        public Color clearColor = Color.black;
    }
    
    public Settings settings = new Settings();

    private RenderToTexturePass pass;
    private RenderTargetHandle destination;

    public override void Create() {
        this.pass = new RenderToTexturePass(this.settings);
        this.pass.renderPassEvent = this.settings.Event;
        this.destination.Init(this.settings.textureName);
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
        this.pass.Setup(this.destination);
        renderer.EnqueuePass(this.pass);
    }
}