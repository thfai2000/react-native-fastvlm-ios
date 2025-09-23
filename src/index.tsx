import { Platform, requireNativeComponent } from 'react-native';
import type { ViewProps } from 'react-native';
import NativeFastVLMCameraModule from './NativeFastVLMCameraModule';

const LINKING_ERROR =
  `The package 'react-native-fastvlm-ios' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({
    ios: "\u2022 You have run 'pod install'\n",
    default: '',
  }) +
  '\u2022 You rebuilt the app after installing the package\n' +
  '\u2022 You are not using Expo managed workflow\n';

type CameraPreviewProps = ViewProps & {
  statusText?: string;
};

const ComponentName = 'FastVLMCameraView';

export const CameraPreview = requireNativeComponent<CameraPreviewProps>(ComponentName);

export async function analyzeCameraData(prompt: string): Promise<string> {
  if (Platform.OS !== 'ios') throw new Error('iOS only');
  
  if (!NativeFastVLMCameraModule) {
    throw new Error(LINKING_ERROR);
  }
  
  return await NativeFastVLMCameraModule.analyzeCameraData(prompt);
}