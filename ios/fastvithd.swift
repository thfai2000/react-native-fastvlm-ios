//
// fastvithd.swift
//
// This file was automatically generated and should not be edited.
//

import CoreML


/// Model Prediction Input Type
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
class fastvithdInput : MLFeatureProvider {

    /// images as 1 × 3 × 1024 × 1024 4-dimensional array of floats
    var images: MLMultiArray

    var featureNames: Set<String> { ["images"] }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        if featureName == "images" {
            return MLFeatureValue(multiArray: images)
        }
        return nil
    }

    init(images: MLMultiArray) {
        self.images = images
    }

    convenience init(images: MLShapedArray<Float>) {
        self.init(images: MLMultiArray(images))
    }

}


/// Model Prediction Output Type
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
class fastvithdOutput : MLFeatureProvider {

    /// Source provided by CoreML
    private let provider : MLFeatureProvider

    /// image_features as 1 × 256 × 3072 3-dimensional array of floats
    var image_features: MLMultiArray {
        provider.featureValue(for: "image_features")!.multiArrayValue!
    }

    /// image_features as 1 × 256 × 3072 3-dimensional array of floats
    var image_featuresShapedArray: MLShapedArray<Float> {
        MLShapedArray<Float>(image_features)
    }

    var featureNames: Set<String> {
        provider.featureNames
    }

    func featureValue(for featureName: String) -> MLFeatureValue? {
        provider.featureValue(for: featureName)
    }

    init(image_features: MLMultiArray) {
        self.provider = try! MLDictionaryFeatureProvider(dictionary: ["image_features" : MLFeatureValue(multiArray: image_features)])
    }

    init(features: MLFeatureProvider) {
        self.provider = features
    }
}


/// Class for model loading and prediction
@available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, visionOS 1.0, *)
class fastvithd {
    let model: MLModel

    /// URL of model assuming it was installed in the same bundle as this class
    class var urlOfModelInThisBundle : URL {
        let bundle = Bundle(for: self)
        return bundle.url(forResource: "fastvithd", withExtension:"mlmodelc")!
    }

    /**
        Construct fastvithd instance with an existing MLModel object.

        Usually the application does not use this initializer unless it makes a subclass of fastvithd.
        Such application may want to use `MLModel(contentsOfURL:configuration:)` and `fastvithd.urlOfModelInThisBundle` to create a MLModel object to pass-in.

        - parameters:
          - model: MLModel object
    */
    init(model: MLModel) {
        self.model = model
    }

    /**
        Construct a model with configuration

        - parameters:
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(configuration: MLModelConfiguration = MLModelConfiguration()) throws {
        try self.init(contentsOf: type(of:self).urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct fastvithd instance with explicit path to mlmodelc file
        - parameters:
           - modelURL: the file url of the model

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL) throws {
        try self.init(model: MLModel(contentsOf: modelURL))
    }

    /**
        Construct a model with URL of the .mlmodelc directory and configuration

        - parameters:
           - modelURL: the file url of the model
           - configuration: the desired model configuration

        - throws: an NSError object that describes the problem
    */
    convenience init(contentsOf modelURL: URL, configuration: MLModelConfiguration) throws {
        try self.init(model: MLModel(contentsOf: modelURL, configuration: configuration))
    }

    /**
        Construct fastvithd instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<fastvithd, Error>) -> Void) {
        load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration, completionHandler: handler)
    }

    /**
        Construct fastvithd instance asynchronously with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - configuration: the desired model configuration
    */
    class func load(configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> fastvithd {
        try await load(contentsOf: self.urlOfModelInThisBundle, configuration: configuration)
    }

    /**
        Construct fastvithd instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
          - handler: the completion handler to be called when the model loading completes successfully or unsuccessfully
    */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration(), completionHandler handler: @escaping (Swift.Result<fastvithd, Error>) -> Void) {
        MLModel.load(contentsOf: modelURL, configuration: configuration) { result in
            switch result {
            case .failure(let error):
                handler(.failure(error))
            case .success(let model):
                handler(.success(fastvithd(model: model)))
            }
        }
    }

    /**
        Construct fastvithd instance asynchronously with URL of the .mlmodelc directory with optional configuration.

        Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

        - parameters:
          - modelURL: the URL to the model
          - configuration: the desired model configuration
    */
    class func load(contentsOf modelURL: URL, configuration: MLModelConfiguration = MLModelConfiguration()) async throws -> fastvithd {
        let model = try await MLModel.load(contentsOf: modelURL, configuration: configuration)
        return fastvithd(model: model)
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as fastvithdInput

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as fastvithdOutput
    */
    func prediction(input: fastvithdInput) throws -> fastvithdOutput {
        try prediction(input: input, options: MLPredictionOptions())
    }

    /**
        Make a prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as fastvithdInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as fastvithdOutput
    */
    func prediction(input: fastvithdInput, options: MLPredictionOptions) throws -> fastvithdOutput {
        let outFeatures = try model.prediction(from: input, options: options)
        return fastvithdOutput(features: outFeatures)
    }

    /**
        Make an asynchronous prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - input: the input to the prediction as fastvithdInput
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as fastvithdOutput
    */
    @available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, visionOS 1.0, *)
    func prediction(input: fastvithdInput, options: MLPredictionOptions = MLPredictionOptions()) async throws -> fastvithdOutput {
        let outFeatures = try await model.prediction(from: input, options: options)
        return fastvithdOutput(features: outFeatures)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - images: 1 × 3 × 1024 × 1024 4-dimensional array of floats

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as fastvithdOutput
    */
    func prediction(images: MLMultiArray) throws -> fastvithdOutput {
        let input_ = fastvithdInput(images: images)
        return try prediction(input: input_)
    }

    /**
        Make a prediction using the convenience interface

        It uses the default function if the model has multiple functions.

        - parameters:
            - images: 1 × 3 × 1024 × 1024 4-dimensional array of floats

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as fastvithdOutput
    */

    func prediction(images: MLShapedArray<Float>) throws -> fastvithdOutput {
        let input_ = fastvithdInput(images: images)
        return try prediction(input: input_)
    }

    /**
        Make a batch prediction using the structured interface

        It uses the default function if the model has multiple functions.

        - parameters:
           - inputs: the inputs to the prediction as [fastvithdInput]
           - options: prediction options

        - throws: an NSError object that describes the problem

        - returns: the result of the prediction as [fastvithdOutput]
    */
    func predictions(inputs: [fastvithdInput], options: MLPredictionOptions = MLPredictionOptions()) throws -> [fastvithdOutput] {
        let batchIn = MLArrayBatchProvider(array: inputs)
        let batchOut = try model.predictions(from: batchIn, options: options)
        var results : [fastvithdOutput] = []
        results.reserveCapacity(inputs.count)
        for i in 0..<batchOut.count {
            let outProvider = batchOut.features(at: i)
            let result =  fastvithdOutput(features: outProvider)
            results.append(result)
        }
        return results
    }
}
