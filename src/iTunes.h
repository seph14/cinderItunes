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

#ifndef AudioLib_iTunes_h
#define AudioLib_iTunes_h

#include "Track.h"

namespace cinder { namespace iTunes {

enum State {
    Stopped            = 0,
    Playing            = 1,
    Paused             = 2,
    Interrupted        = 3,
    SeekingForward     = 4,
    SeekingBackward    = 5
};

class iTunes;
typedef std::shared_ptr<iTunes> iTunesRef;
    
class iTunes{
public:
    typedef std::function<void ()> StateFn;
	
    iTunes( bool useiPodPlayer = false );
    static iTunesRef create( bool useiPodPlayer );
    
    bool    isUsingiPodPlayer();
    
    void    play(PlaylistRef playlist);
    void    play(PlaylistRef playlist, size_t index);
    
    void    resume();
    void    pause();
    void    stop();
    
    void    skipToNext();
    void    skipToPrev();
    void    skipToHead();
    
    void    setPlayheadTime(float time);
    float   getPlayheadTime();
    
    void    setShuffleSongs();
    void    setShuffleAlbums();
    void    setShuffleOff();
    
    void        setPlayingTrack(MPMediaItem* mediaItem);
    TrackRef    getPlayingTrack();
    State       getPlayState();
    
    void    updateInternalState();
    
    void    bindTrackChangeFn( const StateFn &trackFn );
    void    bindStateChangeFn( const StateFn &stateFn );
    void    callTrackChangeFn();
    void    callStateChangeFn();
    
protected:
    
    std::shared_ptr<StateFn>    mTrackChangeFn;
    std::shared_ptr<StateFn>    mStateChangeFn;
    
    bool                        mUseiPodPlayer;
    void*                       miTunesImpl;
    TrackRef                    mTrack;
    State                       mState;
};
    
//static functions
PlaylistRef         getAllTracks();
PlaylistRef         getAlbum(uint64_t album_id);
vector<PlaylistRef> getAlbums();
vector<PlaylistRef> getAlbumsWithArtist(const string &artist_name);
vector<PlaylistRef> getArtists();
    
}}

#endif
