import React, { useState } from 'react';
import { StyleSheet, View, Button } from 'react-native';
import { CameraPreview, analyzeCameraData } from 'react-native-fastvlm-ios';
import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';

export default function HomeScreen() {
  const [statusText, setStatusText] = useState<string>('ready');

  const handleAnalyze = async () => {
    setStatusText('generating...');
    try {
      // analyzeCameraData expects a single prompt string. The native module will read camera data itself.
      const result = await analyzeCameraData('Describe what you see from the camera');
      // show a short snippet of the result
      setStatusText(result?.slice?.(0, 60) ? result.slice(0, 60) : 'completed');
    } catch (e) {
      setStatusText('error');
      console.error('analyze failed', e);
    }
  };

  return (
    <ThemedView style={styles.container}>
      <CameraPreview style={styles.camera} statusText={statusText} />

      <View style={styles.controls}>
        <ThemedText type="subtitle">FastVLM Camera</ThemedText>
        <Button title="Analyze" onPress={handleAnalyze} />
      </View>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  camera: { flex: 1 },
  controls: { padding: 12 },
});
