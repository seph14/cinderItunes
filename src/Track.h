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

#ifndef AudioLib_Track_h
#define AudioLib_Track_h

#include "cinder/Cinder.h"
#include "cinder/app/AppCocoaTouch.h"

#include <vector>
#include <string>
#include <ostream>

#if defined( __OBJC__ )
    @class MPMediaItem;
    @class MPMediaItemCollection;
#else
    class MPMediaItem;
    class MPMediaItemCollection;
#endif

using std::string;
using std::vector;

namespace cinder { namespace iTunes {
    
class Track;
typedef std::shared_ptr<Track> TrackRef;
class Playlist;
typedef std::shared_ptr<Playlist> PlaylistRef;

class Track {
public:
    Track();
    Track(MPMediaItem* _media_item);
    ~Track();
    
    static   TrackRef create(MPMediaItem* _media_item);
    
    string   getTitle();
    string   getAlbumTitle();
    string   getArtist();
    string   getAssetUrl();
    
    bool     isLocalTrack();
    
    uint64_t getAlbumId();
    uint64_t getArtistId();
        
    int         getPlayCount();
    double      getLength();
    ci::Color   color;
    
    MPMediaItem* getMediaItem(){
        return mMediaItem;
    };
        
protected:
    MPMediaItem* mMediaItem;
};
    
class Playlist {
public:
    typedef vector<TrackRef>::iterator Iter;
        
    Playlist();
    Playlist(MPMediaItemCollection* collection);
    ~Playlist();
        
    static PlaylistRef create();
    
    void clear();
    void pushTrack(TrackRef track);
    void pushTrack(Track   *track);
    void popLastTrack(){ tracks.pop_back(); };
        
    string getAlbumTitle();
    string getArtistName();
        
    TrackRef    operator[](const int index) { return tracks[index]; };
    TrackRef    firstTrack()                { return tracks.front();};
    TrackRef    lastTrack()                 { return tracks.back(); };
    Iter        begin()                     { return tracks.begin();};
    Iter        end()                       { return tracks.end();  };
    size_t      size()                      { return tracks.size(); };
        
    MPMediaItemCollection*  getMediaItemCollection();
    vector<TrackRef>        tracks;
};
    
} } // namespace cinder::iTunes

#endif
