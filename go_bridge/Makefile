.PHONY: all clean android-arm64 android-arm android-x86_64 linux-amd64 linux-arm64

all: android-arm64 android-arm linux-amd64

android-arm64:
	./build.sh android arm64

android-arm:
	./build.sh android arm

android-x86_64:
	./build.sh android x86_64

linux-amd64:
	./build.sh linux amd64

linux-arm64:
	./build.sh linux arm64

clean:
	rm -f ../android/app/src/main/jniLibs/arm64-v8a/libjiotv_go.so
	rm -f ../android/app/src/main/jniLibs/armeabi-v7a/libjiotv_go.so
	rm -f ../android/app/src/main/jniLibs/x86_64/libjiotv_go.so
	rm -f ../linux/lib/libjiotv_go.so
	rm -f ../macos/lib/libjiotv_go.dylib
