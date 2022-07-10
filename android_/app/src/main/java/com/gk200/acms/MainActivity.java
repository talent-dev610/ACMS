package com.gk200.acms;

import android.os.Bundle;

import com.jiajiabingcheng.phonelog.PhoneLogPlugin;

import io.flutter.app.FlutterActivity;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        GeneratedPluginRegistrant.registerWith(this);

        PhoneLogPlugin.registerWith(this.registrarFor("phone_log"));
    }
}
