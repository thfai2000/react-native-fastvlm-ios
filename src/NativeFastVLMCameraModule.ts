import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  readonly analyzeCameraData: (prompt: string) => Promise<string>;
}

export default TurboModuleRegistry.getEnforcing<Spec>('FastVLMCameraModule');