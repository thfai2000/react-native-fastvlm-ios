import React, { useState } from 'react';
import { Text, View, StyleSheet, Button, Alert } from 'react-native';
import { CameraPreview, analyzeCameraData } from 'react-native-fastvlm-ios';

export default function App() {
  const [statusText, setStatusText] = useState('ready');
  const [isAnalyzing, setIsAnalyzing] = useState(false);

  const handleAnalyze = async () => {
    try {
      setIsAnalyzing(true);
      setStatusText('generating...');
      
      // Simulate camera data (in real app, this would come from camera)
      const result = await analyzeCameraData('camera_data', 'Describe what you see');
      
      setStatusText('completed');
      Alert.alert('Analysis Result', result);
    } catch (error) {
      setStatusText('error');
      Alert.alert('Error', 'Failed to analyze camera data');
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <View style={styles.container}>
      <Text style={styles.title}>FastVLM Camera Example</Text>
      <View style={styles.cameraContainer}>
        <CameraPreview style={styles.camera} statusText={statusText} />
      </View>
      <Button 
        title={isAnalyzing ? 'Analyzing...' : 'Analyze Camera'} 
        onPress={handleAnalyze}
        disabled={isAnalyzing}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 20,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    textAlign: 'center',
    marginVertical: 20,
  },
  cameraContainer: {
    flex: 1,
    backgroundColor: '#000',
    borderRadius: 10,
    overflow: 'hidden',
    marginBottom: 20,
  },
  camera: {
    flex: 1,
  },
});
