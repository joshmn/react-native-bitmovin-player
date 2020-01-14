import { NativeModules, NativeEventEmitter } from 'react-native';

const { RNBitmovinVideoDownloadModule } = NativeModules;
const EventEmitter = new NativeEventEmitter(RNBitmovinVideoDownloadModule);

const VideoDownload = {};

VideoDownload.download = configuration => RNBitmovinVideoDownloadModule.startDownload(configuration);
VideoDownload.onStartDownload = (callback) => {
  const nativeEvent = "onStartDownload";
  if (!nativeEvent) {
    throw new Error("Invalid event");
  }

  EventEmitter.removeAllListeners(nativeEvent);
  return EventEmitter.addListener(nativeEvent, callback);
}

VideoDownload.onProgress = (callback) => {
  const nativeEvent = "onProgress";
  if (!nativeEvent) {
    throw new Error("Invalid event");
  }

  EventEmitter.removeAllListeners(nativeEvent);
  return EventEmitter.addListener(nativeEvent, callback);
}

VideoDownload.onCompleted = (callback) => {
  const nativeEvent = "onCompleted";
  if (!nativeEvent) {
    throw new Error("Invalid event");
  }

  EventEmitter.removeAllListeners(nativeEvent);
  return EventEmitter.addListener(nativeEvent, callback);
}

VideoDownload.onError = (callback) => {
  const nativeEvent = "onError";
  if (!nativeEvent) {
    throw new Error("Invalid event");
  }

  EventEmitter.removeAllListeners(nativeEvent);
  return EventEmitter.addListener(nativeEvent, callback);
}



export default VideoDownload;