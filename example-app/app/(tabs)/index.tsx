import React, { useState } from 'react';
import { Platform, StyleSheet, View, TouchableOpacity, TextInput, ScrollView, Alert } from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
// import { CameraPreview, analyzeCameraData } from 'react-native-fastvlm-ios';
import { analyzeCameraData } from 'react-native-fastvlm-ios';

export default function HomeScreen() {
  const [analysisResult, setAnalysisResult] = useState<string>('');
  const [isAnalyzing, setIsAnalyzing] = useState<boolean>(false);
  const [prompt, setPrompt] = useState<string>('What do you see in this image?');

  const handleAnalyzePress = async () => {
    if (Platform.OS !== 'ios') {
      Alert.alert('Error', 'This feature is only available on iOS');
      return;
    }

    try {
      setIsAnalyzing(true);
      setAnalysisResult('Analyzing...');
      console.log('Starting analysis with prompt:', prompt);
      const result = await analyzeCameraData(prompt);
      setAnalysisResult(result);
    } catch (error) {
      console.error('Analysis error:', error);
      setAnalysisResult(`Error: ${error instanceof Error ? error.message : 'Unknown error occurred'}`);
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <ThemedView style={styles.container}>
      <ThemedView style={styles.titleContainer}>
        <ThemedText type="title">FastVLM Camera Demo</ThemedText>
      </ThemedView>
      
      {/* <ThemedView style={styles.cameraContainer}>
        <CameraPreview style={styles.cameraPreview} />
      </ThemedView> */}

      <ThemedView style={styles.controlsContainer}>
        <ThemedText type="subtitle">Analysis Prompt:</ThemedText>
        <TextInput
          style={styles.promptInput}
          value={prompt}
          onChangeText={setPrompt}
          placeholder="Enter your prompt here..."
          multiline
          numberOfLines={2}
        />
        
        <TouchableOpacity
          style={[styles.analyzeButton, isAnalyzing && styles.analyzeButtonDisabled]}
          onPress={handleAnalyzePress}
          disabled={isAnalyzing}
        >
          <ThemedText style={styles.buttonText}>
            {isAnalyzing ? 'Analyzing...' : 'Analyze Current Screen'}
          </ThemedText>
        </TouchableOpacity>
      </ThemedView>

      <ThemedView style={styles.resultContainer}>
        <ThemedText type="subtitle">Analysis Result:</ThemedText>
        <ScrollView style={styles.resultScrollView}>
          <TextInput
            style={styles.resultTextArea}
            value={analysisResult}
            onChangeText={setAnalysisResult}
            placeholder="Analysis results will appear here..."
            multiline
            textAlignVertical="top"
          />
        </ScrollView>
      </ThemedView>
    </ThemedView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  titleContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 16,
  },
  cameraContainer: {
    flex: 2,
    backgroundColor: '#000',
    borderRadius: 12,
    overflow: 'hidden',
    marginBottom: 16,
  },
  cameraPreview: {
    flex: 1,
    minHeight: 200,
  },
  controlsContainer: {
    marginBottom: 16,
  },
  promptInput: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 12,
    marginTop: 8,
    marginBottom: 16,
    fontSize: 16,
    minHeight: 60,
    color: '#000',
    backgroundColor: '#fff',
  },
  analyzeButton: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 12,
    paddingHorizontal: 24,
    alignItems: 'center',
  },
  analyzeButtonDisabled: {
    backgroundColor: '#cccccc',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  resultContainer: {
    flex: 1,
  },
  resultScrollView: {
    flex: 1,
    marginTop: 8,
  },
  resultTextArea: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 12,
    fontSize: 14,
    minHeight: 120,
    color: '#000',
    backgroundColor: '#fff',
  },
});
