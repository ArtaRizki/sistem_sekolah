package com.artarizki.sistem_sekolah;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.android.gms.tflite.java.TfLite;
import org.tensorflow.lite.DataType;
import org.tensorflow.lite.InterpreterApi;
import org.tensorflow.lite.InterpreterApi.Options.TfLiteRuntime;
import org.tensorflow.lite.support.image.TensorImage;
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer;
import java.io.FileInputStream;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;

public class FaceHelper {
    private InterpreterApi interpreter;
    private MappedByteBuffer modelBuffer;

    public void init(Activity activity, String modelPath) throws Exception {
        Task<Void> initialTfliteTask = TfLite.initialize(activity);
        FileInputStream inputStream = new FileInputStream(modelPath);
        FileChannel fileChannel = inputStream.getChannel();
        modelBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, 0, fileChannel.size());
        Tasks.await(initialTfliteTask);
        InterpreterApi.Options options = new InterpreterApi.Options();
        options.setRuntime(TfLiteRuntime.FROM_SYSTEM_ONLY);
        interpreter = InterpreterApi.create(modelBuffer, options);
    }

    public float[] getEmbedding(String imagePath) {
        if (interpreter == null) return null;
        Bitmap bitmap = BitmapFactory.decodeFile(imagePath);
        if (bitmap == null) return null;

        TensorImage tensorImage = new TensorImage(DataType.FLOAT32);
        tensorImage.load(BitmapUtils.getResizedBitmap(bitmap, 224, 224));
        
        TensorBuffer outputBuffer = TensorBuffer.createFixedSize(new int[]{1, 2048}, DataType.FLOAT32);
        interpreter.run(tensorImage.getBuffer(), outputBuffer.getBuffer());
        
        return outputBuffer.getFloatArray();
    }
}
