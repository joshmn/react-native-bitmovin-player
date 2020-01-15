import { NativeModules, NativeEventEmitter } from 'react-native';

const { RNBitmovinVideoManagerModule } = NativeModules;
const EventEmitter = new NativeEventEmitter(RNBitmovinVideoManagerModule);

const VideoManager = {};

VideoManager.download = configuration => RNBitmovinVideoManagerModule.startDownload(configuration);
VideoManager.onStartDownload = (callback) => {
  const nativeEvent = "onStartDownload";
  if (!nativeEvent) {
    throw new Error("Invalid event");
  }

  EventEmitter.removeAllListeners(nativeEvent);
  return EventEmitter.addListener(nativeEvent, callback);
}

VideoManager.onProgress = (callback) => {
  const nativeEvent = "onProgress";
  if (!nativeEvent) {
    throw new Error("Invalid event");
  }

  EventEmitter.removeAllListeners(nativeEvent);
  return EventEmitter.addListener(nativeEvent, callback);
}

VideoManager.onCompleted = (callback) => {
  const nativeEvent = "onCompleted";
  if (!nativeEvent) {
    throw new Error("Invalid event");
  }

  EventEmitter.removeAllListeners(nativeEvent);
  return EventEmitter.addListener(nativeEvent, callback);
}

VideoManager.onError = (callback) => {
  const nativeEvent = "onError";
  if (!nativeEvent) {
    throw new Error("Invalid event");
  }

  EventEmitter.removeAllListeners(nativeEvent);
  return EventEmitter.addListener(nativeEvent, callback);
}

VideoManager.delete = (source) => RNBitmovinVideoManagerModule.startDelete(source);

VideoManager.onStartDelete = (callback) => {
  const nativeEvent = "onStartDelete";
  if (!nativeEvent) {
    throw new Error("Invalid event");
  }

  EventEmitter.removeAllListeners(nativeEvent);
  return EventEmitter.addListener(nativeEvent, callback);
}

export default VideoManager;