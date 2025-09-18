import type { ViewProps } from 'react-native';
type CameraPreviewProps = ViewProps & {
    statusText?: string;
};
export declare const CameraPreview: import("react-native").HostComponent<CameraPreviewProps>;
export declare function analyzeCameraData(cameraData: string, prompt: string): Promise<string>;
export {};
//# sourceMappingURL=index.d.ts.map