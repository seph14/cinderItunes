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

#ifndef AudioLib_TrackImpl_h
#define AudioLib_TrackImpl_h

#include "cinder/Filesystem.h"
#include "cinder/Function.h"
#include <string>
#include <ostream>
#include <list>

using std::string;
using std::list;

namespace cinder { namespace iTunes {
class TrackConverter;
typedef std::shared_ptr<TrackConverter> TrackConverterRef;
    
class TrackConverter{
public:
    class Format{
    public:
        int         frameRate;
        int         maxChannel;
        int         dataDepth;
    
        Format(): frameRate(24000), maxChannel(2), dataDepth(8) {}
        Format( int framerate, int maxchannel, int datadepth ){
            this->frameRate  = framerate;
            this->maxChannel = maxchannel;
            this->dataDepth  = datadepth;
        }
    };
    
	typedef std::function<void ()> MsgFn;
    
    TrackConverter();
    TrackConverter( Format format );
    
    ~TrackConverter();
    
    static TrackConverterRef create();
    
    void                startConversion (const string& avAssetUrl, const string& convertedFileName = "");
    void                cancel();
    ci::DataSourceRef   getConvertedFile();
    float               getProgress();
    
    //callback function binding
    void bindConverstionStarted( const MsgFn &startFn ) {
        mStartFunction  = std::shared_ptr<MsgFn>( new MsgFn( startFn )); }
    void bindConverstionProcess( const MsgFn &updateFn ) {
        mUpdateFunction  = std::shared_ptr<MsgFn>( new MsgFn( updateFn )); }
    void bindConverstionFinished( const MsgFn &finishFn ) {
        mFinishFunction  = std::shared_ptr<MsgFn>( new MsgFn( finishFn )); }
    
    //internal function for communication with obj-C implementation
    void sendConverstionStartedMessage  (void* aconverter);
    void sendConverstionUpdatedMessage  (void* aconverter);
    void sendConverstionFinishedMessage (void* aconverter, void* convertedUrl);
    
    Format          mFormat;
protected:
    float               mProgress;
    void*               mCurrentAudioConverter;
    ci::DataSourceRef   mFile;
    
    std::shared_ptr<MsgFn>	mStartFunction;
	std::shared_ptr<MsgFn>	mUpdateFunction;
	std::shared_ptr<MsgFn>	mFinishFunction;
};
}} // namespace cinder::iTunes
#endif
