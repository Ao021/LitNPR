using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class JPA : ScriptableRendererFeature {
    class BlitPass : ScriptableRenderPass {
        public Material blitMaterial = null;
        public FilterMode filterMode { get; set; }
        RenderTargetHandle m_SDFTexture;
        RenderTargetHandle m_Buffer1;
        RenderTargetHandle m_Buffer2;
        string m_ProfilerTag;
        private int iter;
        
        public BlitPass(RenderPassEvent renderPassEvent, Material blitMaterial, int Iter, string tag) {
            this.renderPassEvent = renderPassEvent;
            this.blitMaterial = blitMaterial;
            m_ProfilerTag = tag;
            m_Buffer1.Init("_Buffer1");
            m_Buffer2.Init("_Buffer2");
            iter = Iter;
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData) {
            CommandBuffer cmd = CommandBufferPool.Get(m_ProfilerTag);
            RenderTextureDescriptor opaqueDesc = renderingData.cameraData.cameraTargetDescriptor;
            opaqueDesc.depthBufferBits = 0;
            opaqueDesc.msaaSamples = 1;
            cmd.GetTemporaryRT(m_Buffer1.id, opaqueDesc, filterMode);
            cmd.GetTemporaryRT(m_Buffer2.id, opaqueDesc, filterMode);
            cmd.SetGlobalInt("_Type", 0);
            cmd.SetGlobalInt("_Inverse", 0);
            for (int i = 0; i < iter; ++i)
            {
                cmd.SetGlobalInt("_Level", i);
                cmd.Blit(m_Buffer1.Identifier(),m_Buffer2.Identifier(),blitMaterial);
                cmd.SetGlobalInt("_Level", ++i);
                cmd.Blit(m_Buffer2.Identifier(),m_Buffer1.Identifier(),blitMaterial);
            }
            cmd.SetGlobalInt("_Type", 1);
            cmd.Blit(m_Buffer1.Identifier(), m_Buffer2.Identifier(), blitMaterial);
            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }
        
        public override void FrameCleanup(CommandBuffer cmd) {
            if(m_Buffer1.id != -1)cmd.ReleaseTemporaryRT(m_Buffer1.id);
            if(m_Buffer2.id != -1)cmd.ReleaseTemporaryRT(m_Buffer2.id);
        }
    }

    [System.Serializable]
    public class Settings {
        public RenderPassEvent Event = RenderPassEvent.AfterRenderingOpaques;
        public Material blitMaterial = null;
        public int iter = 15;
    }
    public Settings settings = new Settings();
    RenderTargetHandle m_RenderTextureHandle;
    BlitPass blitPass;
    public override void Create() {
        blitPass = new BlitPass(settings.Event, settings.blitMaterial, settings.iter, name);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData) {
        if (settings.blitMaterial == null) {
            Debug.LogWarningFormat("Missing Blit Material. {0} blit pass will not execute. Check for missing reference in the assigned renderer.", GetType().Name);
            return;
        }
        renderer.EnqueuePass(blitPass);
    }
}