package com.xxsnakerxx.RNBitmovinPlayer;

import android.content.ContextWrapper;

import com.bitmovin.player.IllegalOperationException;
import com.bitmovin.player.NoConnectionException;
import com.bitmovin.player.api.event.data.ErrorEvent;
import com.bitmovin.player.config.media.HLSSource;
import com.bitmovin.player.config.media.SourceItem;
import com.bitmovin.player.offline.OfflineContentManager;
import com.bitmovin.player.offline.OfflineContentManagerListener;
import com.bitmovin.player.offline.OfflineSourceItem;
import com.bitmovin.player.offline.options.AudioOfflineOptionEntry;
import com.bitmovin.player.offline.options.OfflineContentOptions;
import com.bitmovin.player.offline.options.OfflineOptionEntryAction;
import com.bitmovin.player.offline.options.OfflineOptionEntryState;
import com.bitmovin.player.offline.options.TextOfflineOptionEntry;
import com.bitmovin.player.offline.options.VideoOfflineOptionEntry;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.google.gson.Gson;

import java.io.File;
import java.io.IOException;

import javax.xml.transform.Source;

import androidx.annotation.NonNull;

public class RNBitmovinVideoManagerModule extends ReactContextBaseJavaModule implements OfflineContentManagerListener {

    private final ReactApplicationContext reactContext;
    private DeviceEventManagerModule.RCTDeviceEventEmitter eventEmitter;
    private File rootFolder;
    private Gson gson = new Gson();
    private String currentAction;

    private OfflineContentOptions offlineOptions;
    private OfflineContentManager offlineContentManager;

    @NonNull
    @Override
    public String getName() {
        return "RNBitmovinVideoManagerModule";
    }

    public RNBitmovinVideoManagerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @ReactMethod
    public void startDownload(ReadableMap configuration) {
        this.currentAction = "DOWNLOAD";
        this.eventEmitter = this.reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class);
        this.rootFolder = this.getReactApplicationContext().getDir("offline", ContextWrapper.MODE_PRIVATE);

        String url = configuration.getString("url");
        if (url == null) {
            eventEmitter.emit("onError", "URL not provided");
        } else {
            SourceItem sourceItem = new SourceItem(url);

            if (configuration.hasKey("thumbnail") && configuration.getString("thumbnail") != null) {
                sourceItem.setThumbnailTrack(configuration.getString("thumbnail"));
            }

            if (configuration.hasKey("title") && configuration.getString("title") != null) {
                sourceItem.setTitle(configuration.getString("title"));
            }

            if (configuration.hasKey("poster") && configuration.getString("poster") != null) {
                sourceItem.setPosterImage(configuration.getString("poster"), false);
            }

            this.offlineContentManager = OfflineContentManager.getOfflineContentManager(sourceItem, this.rootFolder.getPath(), url, this, this.getReactApplicationContext());
            this.offlineContentManager.getOptions();
        }
    }

    @ReactMethod
    public void startDelete(String source) {
        this.currentAction = "DELETE";
        this.eventEmitter = this.reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class);
        this.rootFolder = this.getReactApplicationContext().getDir("offline", ContextWrapper.MODE_PRIVATE);

        this.eventEmitter.emit("onStartDelete", "");

        if (source == null || source.equals("")) {
            this.eventEmitter.emit("onError", "Source not provided");
        } else {
            SourceItem offlineSourceItem = this.gson.fromJson(source, SourceItem.class);

            HLSSource hls = offlineSourceItem.getHlsSource();
            String url = hls.getUrl();

            this.offlineContentManager = OfflineContentManager.getOfflineContentManager(offlineSourceItem, this.rootFolder.getAbsolutePath(), url, this, this.getReactApplicationContext());
            this.offlineContentManager.deleteAll();
        }
    }

    @Override
    public void onCompleted(SourceItem sourceItem, OfflineContentOptions offlineContentOptions) {
        this.offlineOptions = offlineContentOptions;

        try {
            OfflineSourceItem offlineSourceItem = this.offlineContentManager.getOfflineSourceItem();
            Object data = this.gson.toJson(offlineSourceItem);

            if (offlineSourceItem == null || data.equals("null")) {
                this.eventEmitter.emit("onCompleted", "");
            } else {
                eventEmitter.emit("onCompleted", data);
            }
        } catch (IOException e) {
            e.printStackTrace();
            eventEmitter.emit("onError", e.getMessage());
        }
    }

    @Override
    public void onError(SourceItem sourceItem, ErrorEvent errorEvent) {
        eventEmitter.emit("onError", errorEvent.getMessage());
    }

    @Override
    public void onProgress(SourceItem sourceItem, float progress) {
        eventEmitter.emit("onProgress", progress);
    }

    @Override
    public void onOptionsAvailable(SourceItem sourceItem, OfflineContentOptions offlineContentOptions) {
        this.offlineOptions = offlineContentOptions;

        VideoOfflineOptionEntry videoEntry = (VideoOfflineOptionEntry) offlineContentOptions.getVideoOptions().get(0);
        AudioOfflineOptionEntry audioEntry = (AudioOfflineOptionEntry) offlineContentOptions.getAudioOptions().get(0);

        OfflineOptionEntryState offlineOptionEntryState = videoEntry.getState();

        if (this.currentAction.equals("DOWNLOAD")) {
            switch (offlineOptionEntryState.name()) {
                case "NOT_DOWNLOADED":
                    try {
                        videoEntry.setAction(OfflineOptionEntryAction.DOWNLOAD);
                        audioEntry.setAction(OfflineOptionEntryAction.DOWNLOAD);
                    } catch (IllegalOperationException e) {
                        e.printStackTrace();
                        eventEmitter.emit("onError", e.getMessage());
                    }


                    try {
                        this.offlineContentManager.process(offlineContentOptions);
                    } catch (NoConnectionException e) {
                        e.printStackTrace();
                        eventEmitter.emit("onError", e.getMessage());
                    }

                    eventEmitter.emit("onStartDownload", "");
                    break;
                case "DOWNLOADED":
                    try {
                        OfflineSourceItem offlineSourceItem = this.offlineContentManager.getOfflineSourceItem();
                        Object data = this.gson.toJson(offlineSourceItem);


                        eventEmitter.emit("onCompleted", data);
                    } catch (IOException e) {
                        e.printStackTrace();
                        eventEmitter.emit("onError", e.getMessage());
                    }
                    break;
                case "SUSPENDED":
                    this.offlineContentManager.resume();
                    break;
                case "FAILED":
                    this.currentAction = "DELETE";
                    this.eventEmitter.emit("onError", "Error trying to download video");
                    this.offlineContentManager.deleteAll();
                    break;
                default:
                    break;
            }
        }
    }

    @Override
    public void onDrmLicenseUpdated(SourceItem sourceItem) {
    }

    @Override
    public void onSuspended(SourceItem sourceItem) {
        this.offlineContentManager.resume();
    }

    @Override
    public void onResumed(SourceItem sourceItem) {
    }
}
