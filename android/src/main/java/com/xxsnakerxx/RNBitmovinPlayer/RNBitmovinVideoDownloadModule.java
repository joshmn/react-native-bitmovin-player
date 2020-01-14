package com.xxsnakerxx.RNBitmovinPlayer;

import android.content.ContextWrapper;

import com.bitmovin.player.IllegalOperationException;
import com.bitmovin.player.NoConnectionException;
import com.bitmovin.player.api.event.data.ErrorEvent;
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

import androidx.annotation.NonNull;

public class RNBitmovinVideoDownloadModule extends ReactContextBaseJavaModule implements OfflineContentManagerListener {

    private final ReactApplicationContext reactContext;
    private DeviceEventManagerModule.RCTDeviceEventEmitter eventEmitter;
    private File rootFolder;
    private Gson gson = new Gson();

    private OfflineContentOptions offlineOptions;
    private OfflineContentManager offlineContentManager;

    @NonNull
    @Override
    public String getName() {
        return "RNBitmovinVideoDownloadModule";
    }

    public RNBitmovinVideoDownloadModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    @ReactMethod
    public void startDownload(ReadableMap configuration) {
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

    @Override
    public void onCompleted(SourceItem sourceItem, OfflineContentOptions offlineContentOptions) {
        this.offlineOptions = offlineContentOptions;

        try {
            Object data = null;

            while (data == null) {
                OfflineSourceItem offlineSourceItem = this.offlineContentManager.getOfflineSourceItem();
                data = this.gson.toJson(offlineSourceItem);
            }

            eventEmitter.emit("onCompleted", data);
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
        TextOfflineOptionEntry textEntry = (TextOfflineOptionEntry) offlineContentOptions.getTextOptions().get(0);

        OfflineOptionEntryState offlineOptionEntryState = videoEntry.getState();

        switch (offlineOptionEntryState.name()) {
            case "NOT_DOWNLOADED":
                try {
                    videoEntry.setAction(OfflineOptionEntryAction.DOWNLOAD);
                    audioEntry.setAction(OfflineOptionEntryAction.DOWNLOAD);
                    textEntry.setAction(OfflineOptionEntryAction.DOWNLOAD);
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

            case "DOWNLOADING":
            case "SUSPENDED":
                this.offlineContentManager.resume();
                break;
            default:
                break;
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
