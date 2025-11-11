package com.example.myapp;
import android.app.*;
import android.os.*;
import android.widget.*;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText("Hello from Termux!");
        setContentView(tv);
    }
}
