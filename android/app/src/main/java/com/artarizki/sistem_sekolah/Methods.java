package com.artarizki.sistem_sekolah;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class Methods {
    private MethodCall call;
    private MethodChannel.Result result;

    public Methods(MethodCall call, MethodChannel.Result result) {
        this.call = call;
        this.result = result;
    }

    public static Methods get(MethodCall call, MethodChannel.Result result) {
        return new Methods(call, result);
    }
}
