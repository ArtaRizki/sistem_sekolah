package com.artarizki.sistem_sekolah;

import android.app.Activity;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;
import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.android.gms.tflite.java.TfLite;
import org.tensorflow.lite.DataType;
import org.tensorflow.lite.InterpreterApi;
import org.tensorflow.lite.InterpreterApi.Options.TfLiteRuntime;
import org.tensorflow.lite.support.image.ImageProcessor;
import org.tensorflow.lite.support.image.TensorImage;
import org.tensorflow.lite.support.image.ops.ResizeOp;
import org.tensorflow.lite.support.tensorbuffer.TensorBuffer;
import java.io.FileInputStream;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;

public class FaceHelper {
    private static final String TAG = "FaceHelper";
    private InterpreterApi interpreter;
    private MappedByteBuffer modelBuffer;

    public boolean isInitialized() {
        return interpreter != null;
    }

    public void init(Activity activity, String modelPath) throws Exception {
        try {
            Task<Void> initialTfliteTask = TfLite.initialize(activity.getApplicationContext());
            Tasks.await(initialTfliteTask);

            FileInputStream inputStream = new FileInputStream(modelPath);
            FileChannel fileChannel = inputStream.getChannel();
            modelBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, 0, fileChannel.size());

            InterpreterApi.Options options = new InterpreterApi.Options();
            options.setRuntime(TfLiteRuntime.FROM_SYSTEM_ONLY);
            interpreter = InterpreterApi.create(modelBuffer, options);
            Log.d(TAG, "Interpreter initialized successfully");
        } catch (Exception e) {
            Log.e(TAG, "Initialization failed: " + e.getMessage());
            throw e;
        }
    }

    public float[] getEmbedding(String imagePath) throws Exception {
        if (interpreter == null) {
            throw new Exception("Interpreter not initialized");
        }
        
        Bitmap bitmap = BitmapFactory.decodeFile(imagePath);
        if (bitmap == null) {
            throw new Exception("Failed to decode image at " + imagePath);
        }

        try {
            // Get input shape from model
            int[] inputShape = interpreter.getInputTensor(0).shape(); // e.g., [1, 224, 224, 3]
            int inputH = inputShape[1];
            int inputW = inputShape[2];

            ImageProcessor imageProcessor = new ImageProcessor.Builder()
                    .add(new ResizeOp(inputH, inputW, ResizeOp.ResizeMethod.BILINEAR))
                    .build();

            TensorImage tensorImage = new TensorImage(DataType.FLOAT32);
            tensorImage.load(bitmap);
            tensorImage = imageProcessor.process(tensorImage);

            // Get output shape from model
            int[] outputShape = interpreter.getOutputTensor(0).shape(); // e.g., [1, 512] or [1, 2048]
            TensorBuffer outputBuffer = TensorBuffer.createFixedSize(outputShape, DataType.FLOAT32);

            interpreter.run(tensorImage.getBuffer(), outputBuffer.getBuffer());
            return outputBuffer.getFloatArray();
        } catch (Exception e) {
            Log.e(TAG, "Embedding generation failed: " + e.getMessage());
            throw e;
        } finally {
            if (bitmap != null && !bitmap.isRecycled()) {
                bitmap.recycle();
            }
        }
    }
}

