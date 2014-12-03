/*
 ==============================================================================
 
 This project is based on notlion's cinder ipod library.
 https://github.com/notlion/CinderIPod
 Thanks a lot for the code to start.
 
 This library added several new features for the new iOS versions, including
 1) check is a sound track is local file or not (cloud file that doesn't have asset url);
 2) asset url access;
 3) copy track file to current app's domain;
 4) init with ipod player so that music playback won't be stopped after the app goes sleep.
 
 This file is part of the iOS iTunes library for Cinder
 Copyright 2014-12 by seph li.
 
 This file is part of the iOS iTunes library for Cinder
 Copyright 2014-05 by seph li.
 
 ------------------------------------------------------------------------------
 
 cinderItunes is provided under the terms of The MIT License (MIT):
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 ==============================================================================
 */

#include "TrackConverter.h"
#include "cinder/DataSource.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

using cinder::iTunes::TrackConverter;
using namespace std;

//Obj-C AudioConverter class for implementation of TrackConverter
//==============================================================================
@interface AudioConverter : NSObject{
@private
    TrackConverter* owner;
}

@property (readonly) float progress;
@property bool cancelConverting;
@property (assign) NSString* exportName;

@end

//==============================================================================
@implementation AudioConverter

@synthesize progress;
@synthesize cancelConverting;
@synthesize exportName;

- (id) initWithOwner: (TrackConverter*) owner_{
    if ((self = [super init]) != nil){
        owner = owner_;
    }
    return self;
}

- (void) dealloc{
    [super dealloc];
}

//==============================================================================
- (void) convertAudioFile: (NSURL*) assetURL {
    cancelConverting = false;
    progress         = 0.0f;
    
    @autoreleasepool{
	// set up an AVAssetReader to read from the iPod Library
	AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL: assetURL options: nil];
    
	NSError* assetError = nil;
	AVAssetReader* assetReader = [[AVAssetReader assetReaderWithAsset: songAsset
                                                                error: &assetError]
								  retain];
	if (assetError){
		NSLog (@"error: %@", assetError);
        [assetReader release];
        return;
	}
    
	AVAssetReaderOutput* assetReaderOutput = [[AVAssetReaderAudioMixOutput
                                               assetReaderAudioMixOutputWithAudioTracks: songAsset.tracks
                                               audioSettings: nil]
                                              retain];
	
    if (! [assetReader canAddOutput: assetReaderOutput]){
		NSLog (@"can't add reader output");
        [assetReaderOutput release];
        [assetReader release];
		return;
	}
    
	[assetReader addOutput: assetReaderOutput];
	
	NSArray* dirs = NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectoryPath = [dirs objectAtIndex: 0];
	NSString* exportPath = [[documentsDirectoryPath stringByAppendingPathComponent: exportName] retain];
	if ([[NSFileManager defaultManager] fileExistsAtPath: exportPath]){
		[[NSFileManager defaultManager] removeItemAtPath: exportPath error: nil];
	}
    
	NSURL* exportURL            = [NSURL fileURLWithPath: exportPath];
	AVAssetWriter* assetWriter  = [[AVAssetWriter assetWriterWithURL: exportURL
                                                            fileType: AVFileTypeCoreAudioFormat
                                                               error: &assetError]
								  retain];
	if (assetError){
		NSLog (@"error: %@", assetError);
        [assetReaderOutput release];
        [assetWriter release];
        [assetReader release];
        [exportPath  release];
		return;
	}
    
    AVAssetTrack* avAssetTrack = [songAsset.tracks objectAtIndex: 0];
    CMAudioFormatDescriptionRef formatDescription = (CMAudioFormatDescriptionRef)[avAssetTrack.formatDescriptions objectAtIndex: 0];
    const AudioStreamBasicDescription* audioDesc = CMAudioFormatDescriptionGetStreamBasicDescription (formatDescription);
    NSInteger channelPerFrame = audioDesc->mChannelsPerFrame;
    if( channelPerFrame > owner->mFormat.maxChannel )
        channelPerFrame = owner->mFormat.maxChannel;
    
    AudioChannelLayout channelLayout;
	memset (&channelLayout, 0, sizeof (AudioChannelLayout));
	if( channelPerFrame > 1 )
         channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    else channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
        //kAudioFormatAppleIMA4
        //kAudioFormatLinearPCM
        //kAudioFormatMPEG4AAC
        
    /*NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithInt: kAudioFormatAppleIMA4],        AVFormatIDKey,
                                        [NSNumber numberWithInt: owner->mFormat.frameRate],     AVSampleRateKey,
                                        [NSNumber numberWithInt: channelPerFrame],              AVNumberOfChannelsKey,
                                        [NSData dataWithBytes:   &channelLayout length: sizeof (AudioChannelLayout)], AVChannelLayoutKey,
                                        nil];*/
        
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithInt: kAudioFormatLinearPCM],        AVFormatIDKey,
									[NSNumber numberWithInt: owner->mFormat.frameRate],     AVSampleRateKey,
									[NSNumber numberWithInt: (int)channelPerFrame],              AVNumberOfChannelsKey,
									[NSData dataWithBytes:   &channelLayout length: sizeof (AudioChannelLayout)], AVChannelLayoutKey,
									[NSNumber numberWithInt: owner->mFormat.dataDepth],     AVLinearPCMBitDepthKey,
									[NSNumber numberWithBool: NO],                          AVLinearPCMIsNonInterleaved,
									[NSNumber numberWithBool: NO],                          AVLinearPCMIsFloatKey,
									[NSNumber numberWithBool: NO],                          AVLinearPCMIsBigEndianKey,
									nil];

    /*NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt: kAudioFormatMPEG4AAC],         AVFormatIDKey,
                                    [NSNumber numberWithInt: owner->mFormat.frameRate],     AVSampleRateKey,
                                    [NSNumber numberWithInt: channelPerFrame],              AVNumberOfChannelsKey,
                                    [ NSNumber numberWithInt: 8000 ],                     AVEncoderBitRateKey,
                                    [NSData dataWithBytes:   &channelLayout length: sizeof (AudioChannelLayout)], AVChannelLayoutKey,
                                    nil];*/
        
	AVAssetWriterInput *assetWriterInput = [[AVAssetWriterInput assetWriterInputWithMediaType: AVMediaTypeAudio
                                                                               outputSettings: outputSettings]
											retain];
    
	if ([assetWriter canAddInput: assetWriterInput]){
		[assetWriter addInput: assetWriterInput];
        owner->sendConverstionStartedMessage (self);
	}else{
		NSLog (@"can't add asset writer input");
		[assetWriter release];
        [assetReader release];
        [exportPath  release];
		[assetReaderOutput release];
        [assetWriterInput release];
        return;
	}
	
	assetWriterInput.expectsMediaDataInRealTime = NO;
    
	[assetWriter startWriting];
	[assetReader startReading];
    
	AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
	CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
	[assetWriter startSessionAtSourceTime: startTime];
	
    //NSLog (@"duration: %f", CMTimeGetSeconds (soundTrack.timeRange.duration));
    double finalSizeByteCount         = soundTrack.timeRange.duration.value * 2 * sizeof (SInt16);
	__block UInt64 convertedByteCount = 0;
	
    //==============================================================================
    // reading
    //==============================================================================
    dispatch_queue_t mediaInputQueue = dispatch_queue_create ("mediaInputQueue", NULL);
    [assetWriterInput requestMediaDataWhenReadyOnQueue: mediaInputQueue
											usingBlock: ^
	 {
         CMSampleBufferRef nextBuffer;
         while (assetWriterInput.readyForMoreMediaData){
             
             nextBuffer = [assetReaderOutput copyNextSampleBuffer];
             
             if (nextBuffer && ! cancelConverting){
                 // append buffer
                 [assetWriterInput appendSampleBuffer: nextBuffer];
                 convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
                 progress = (float) convertedByteCount / finalSizeByteCount;
             
                 CMSampleBufferInvalidate(nextBuffer);
                 CFRelease(nextBuffer);
                 nextBuffer = nil;
                 
                 NSNumber* progressNumber = [NSNumber numberWithDouble: progress];
                 [self performSelectorOnMainThread: @selector (updateProgress:)
                                        withObject: progressNumber
                                     waitUntilDone: NO];
            
             }else{
                //finish
                [assetWriterInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^(){
                    //NSLog (@"finished writing");
                }];
                [assetReader cancelReading];
                
                 //NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]
                //                                    attributesOfItemAtPath: exportPath
                //                                    error: nil];
                //NSLog (@"done. file size is %llu", [outputFileAttributes fileSize]);
                     
                // release all buffers
                [assetReader       release];
                [assetReaderOutput release];
                [assetWriter       release];
                [assetWriterInput  release];
                [exportPath        release];
                
                [self performSelectorOnMainThread: @selector (finishedConverting:)
                                       withObject: exportURL
                                    waitUntilDone: NO];
                     
                break;
            }
        }
	 }];
    }
}

- (void) cancel{
    cancelConverting = true;
}

- (void) updateProgress: (NSNumber*) progressFloat{
    owner->sendConverstionUpdatedMessage (self);
}

- (void) finishedConverting: (NSURL*) exportURL{
    owner->sendConverstionFinishedMessage (self, exportURL);
}
@end
//==============================================================================
//AudioConverter done

//implementation of c++ class TrackConverter
namespace cinder { namespace iTunes {
    
    TrackConverter::TrackConverter() : mCurrentAudioConverter (nullptr), mFormat( Format() ) {}
    TrackConverter::TrackConverter( Format format ) : mCurrentAudioConverter (nullptr), mFormat( format ) {}
    TrackConverter::~TrackConverter(){ if(mCurrentAudioConverter != nil) [(AudioConverter*)mCurrentAudioConverter release]; }
    
    TrackConverterRef TrackConverter::create(){
        return shared_ptr<TrackConverter>( new TrackConverter() );
    }
    
    //==============================================================================
    //conversion functions
    void TrackConverter::startConversion (const string& avAssetUrl, const string& convertedFileName){
        
        mFile = nullptr;
        
        if(mCurrentAudioConverter != nil)
            [(AudioConverter*) mCurrentAudioConverter release];
        mCurrentAudioConverter = (AudioConverter*)[[AudioConverter alloc] initWithOwner: this];
        
        if (mCurrentAudioConverter != nil){
            string fileName (convertedFileName);
            if (fileName.length() == 0)
                fileName = "track";
            fileName += ".wav";
            //fileName += ".m4a";
            ((AudioConverter*)mCurrentAudioConverter).exportName = [NSString stringWithUTF8String: fileName.c_str()];
            NSURL* idUrl = [NSURL URLWithString: [NSString stringWithUTF8String: avAssetUrl.c_str()]];
            [(AudioConverter*)mCurrentAudioConverter convertAudioFile: idUrl];
        }
    }
    
    void TrackConverter::cancel(){
        AudioConverter* audioConverter = (AudioConverter*) mCurrentAudioConverter;
        if (audioConverter != nil)
            [audioConverter cancel];
    }
    
    DataSourceRef TrackConverter::getConvertedFile(){
        return mFile;
    }
    
    float TrackConverter::getProgress(){
        return mProgress;
    }
    
    //==============================================================================
    //communication functions with obj-c implementation class
    void TrackConverter::sendConverstionStartedMessage (void* aconverter){
        (*mStartFunction)();
    }
    
    void TrackConverter::sendConverstionUpdatedMessage (void* aconverter){
        AudioConverter* converter = (AudioConverter*) aconverter;
        mProgress = converter.progress;
        (*mUpdateFunction)();
    }
    
    void TrackConverter::sendConverstionFinishedMessage (void* aconverter, void* convertedUrl){
        string absolutepath = [((NSURL*) convertedUrl).absoluteString UTF8String];
        //app::console() << absolutepath << endl;
        [(AudioConverter*) mCurrentAudioConverter release];
        mCurrentAudioConverter = nil;
        mFile =  loadFile( absolutepath );
        (*mFinishFunction)();
    }
}}
