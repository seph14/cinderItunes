/*
 ==============================================================================
 
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

#include "iTunes.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface iTunesImpl : NSObject <AVAudioPlayerDelegate> {
@public
    MPMusicPlayerController     *mPlayer;
	cinder::iTunes::iTunes      *iTunes;
}
@end

@implementation iTunesImpl

-(id)init:(cinder::iTunes::iTunes*)_itunes{
    self    = [super init];
    iTunes  = _itunes;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    //prepare music player
    if ( iTunes->isUsingiPodPlayer() ) {
        mPlayer = [MPMusicPlayerController iPodMusicPlayer];
        if ([mPlayer nowPlayingItem])
            [mPlayer stop];
        //    iTunes->updateInternalState();
    } else {
        mPlayer = [MPMusicPlayerController applicationMusicPlayer];
        [mPlayer setShuffleMode: MPMusicShuffleModeOff];
        [mPlayer setRepeatMode: MPMusicRepeatModeNone];
    }
    
    //register notification
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver: self
           selector: @selector (onStateChanged:)
               name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
             object: mPlayer];
    
    [nc addObserver: self
           selector: @selector (onTrackChanged:)
               name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
             object: mPlayer];
    
    [mPlayer beginGeneratingPlaybackNotifications];
    return self;
}

- (void)pause{
    [mPlayer pause];
}

- (void)stop{
    [mPlayer stop];
}

- (void)resume{
    if([mPlayer playbackState] == MPMusicPlaybackStatePaused)
        [mPlayer play];
}

- (void)setPlayheadTime:(float)time{
    mPlayer.currentPlaybackTime = time;
}

- (void)setPlaybackRate:(float)rate{
    mPlayer.currentPlaybackRate = rate;
}

- (float)getPlayheadTime{
    return mPlayer.currentPlaybackTime;
}

- (void)skipToNext{
    [mPlayer skipToNextItem];
}

- (void)skipToPrev{
    [mPlayer skipToPreviousItem];
}

- (void)skipToHead{
    [mPlayer skipToBeginning];
}

- (void) setShuffleSongs{
    [mPlayer setShuffleMode: MPMusicShuffleModeSongs];
}

- (void) setShuffleAlbums{
    [mPlayer setShuffleMode: MPMusicShuffleModeAlbums];
}

- (void) setShuffleOff{
    [mPlayer setShuffleMode: MPMusicShuffleModeOff];
}

- (MPMediaItem*)play:(MPMediaItemCollection*)collection atIndex:(NSUInteger)index{
    if([mPlayer playbackState] == MPMusicPlaybackStatePlaying)
        [mPlayer stop];
    [mPlayer setQueueWithItemCollection: collection];
    mPlayer.nowPlayingItem = [[collection items] objectAtIndex: index];
    [mPlayer play];
    return mPlayer.nowPlayingItem;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
												  object: mPlayer];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self
													name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
												  object: mPlayer];
    
	[mPlayer endGeneratingPlaybackNotifications];
	[mPlayer release];
    [super dealloc];
}

- (void)onStateChanged:(NSNotification *)notification{
    //if( iTunes->mStateChangeFn != nil)
    //    iTunes->mStateChangeFn();
    iTunes->callStateChangeFn();
}

- (void)onTrackChanged:(NSNotification *)notification{
    //if( iTunes->mTrackChangeFn != nil)
    //    iTunes->mTrackChangeFn();
    iTunes->callTrackChangeFn();
}

- (MPMusicPlaybackState)getPlaybackState{
    return [mPlayer playbackState];
}

@end
    
using namespace std;
using namespace ci;
    
namespace cinder { namespace iTunes {
    
    ////////////////////////////////////////////////////////////////////////////
    // iTunes class/////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    iTunes::iTunes( bool useiPodPlayer ){
        mState          = State::Stopped;
        mUseiPodPlayer  = useiPodPlayer;
        miTunesImpl     = [[iTunesImpl alloc] init: this];
        mTrack          = nullptr;
    }
    
    iTunesRef iTunes::create( bool useiPodPlayer ){
        return shared_ptr<iTunes>( new iTunes(useiPodPlayer) );
    }
    
    bool iTunes::isUsingiPodPlayer(){
        return mUseiPodPlayer;
    }
    
    void iTunes::bindTrackChangeFn( const StateFn &trackFn ){
        mTrackChangeFn = shared_ptr<StateFn>( new StateFn(trackFn) );
    }
    
    void iTunes::bindStateChangeFn( const StateFn &stateFn ){
        mStateChangeFn = shared_ptr<StateFn>( new StateFn(stateFn) );
    }
    
    void iTunes::callTrackChangeFn(){
        if( mTrackChangeFn != nullptr )
            (*mTrackChangeFn)();
    }
    
    void iTunes::callStateChangeFn(){
        if( mStateChangeFn != nullptr )
            (*mStateChangeFn)();
    }
    
    void iTunes::updateInternalState(){
        MPMusicPlaybackState mpState = [((iTunesImpl*)miTunesImpl) getPlaybackState];
        if( mpState == MPMusicPlaybackStatePaused ){
            mState = State::Paused;
        }else if( mpState == MPMusicPlaybackStateInterrupted ){
            mState = State::Interrupted;
        }else if( mpState == MPMusicPlaybackStatePlaying ){
            mState = State::Playing;
        }else if( mpState == MPMusicPlaybackStateSeekingBackward ){
            mState = State::SeekingBackward;
        }else if( mpState == MPMusicPlaybackStateSeekingForward ){
            mState = State::SeekingForward;
        }else if( mpState == MPMusicPlaybackStateStopped ){
            mState = State::Stopped;
        }
    }
    
    void iTunes::setPlayingTrack(MPMediaItem* mediaItem){
        mTrack = Track::create(mediaItem);
    }
    
    void iTunes::play(PlaylistRef playlist){
        play(playlist, 0);
    }
    
    void iTunes::play(PlaylistRef playlist, size_t index){
        if(index >= playlist->size())
            return;
        MPMediaItemCollection *collection = playlist->getMediaItemCollection();
        mTrack = Track::create( [(iTunesImpl*)miTunesImpl play:collection atIndex:index] );
    }
    
    void iTunes::resume(){
        [(iTunesImpl*)miTunesImpl resume];
    }
    
    void iTunes::stop(){
        [(iTunesImpl*)miTunesImpl stop];
        
    }

    void iTunes::pause(){
        [(iTunesImpl*)miTunesImpl pause];
    }
    
    void iTunes::skipToNext(){
        [(iTunesImpl*)miTunesImpl skipToNext];
    }
    
    void iTunes::skipToPrev(){
        [(iTunesImpl*)miTunesImpl skipToPrev];
    }
    
    void iTunes::skipToHead(){
        [(iTunesImpl*)miTunesImpl skipToHead];
    }
    
    void iTunes::setPlayheadTime(float time){
        [(iTunesImpl*)miTunesImpl setPlaybackRate:time];
    }
    
    float iTunes::getPlayheadTime(){
        return [(iTunesImpl*)miTunesImpl getPlayheadTime];
    }
    
    void iTunes::setShuffleSongs(){
        
    }
    
    void iTunes::setShuffleAlbums(){
        
    }
    
    void iTunes::setShuffleOff(){
        
    }
    
    TrackRef iTunes::getPlayingTrack(){
        return mTrack;
    }
    
    State iTunes::getPlayState(){
        return mState;
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // Library Functions/////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    PlaylistRef getAllTracks(){
        MPMediaQuery *query           = [MPMediaQuery songsQuery];
        MPMediaItemCollection *tracks = [MPMediaItemCollection collectionWithItems: [query items]];
        return PlaylistRef(new Playlist(tracks));
    }
    
    PlaylistRef getAlbum(uint64_t album_id){
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate: [MPMediaPropertyPredicate
                                    predicateWithValue: [NSNumber numberWithInteger: MPMediaTypeMusic]
                                    forProperty: MPMediaItemPropertyMediaType
                                    ]];
        [query addFilterPredicate: [MPMediaPropertyPredicate
                                    predicateWithValue: [NSNumber numberWithUnsignedLongLong: album_id]
                                    forProperty: MPMediaItemPropertyAlbumPersistentID
                                    ]];
        MPMediaItemCollection *tracks = [MPMediaItemCollection collectionWithItems: [query items]];
        [query release];
        return PlaylistRef(new Playlist(tracks));
    }
    
    vector<PlaylistRef> getAlbums(){
        vector<PlaylistRef> albums;
        MPMediaQuery *query   = [MPMediaQuery albumsQuery];
        NSArray *query_groups = [query collections];
        for(MPMediaItemCollection *group in query_groups){
            PlaylistRef album = PlaylistRef(new Playlist(group));
            albums.push_back(album);
        }
        return albums;
    }
    
    vector<PlaylistRef> getAlbumsWithArtist(const string &artist_name){
        MPMediaQuery *query = [[MPMediaQuery alloc] init];
        [query addFilterPredicate: [MPMediaPropertyPredicate
                                    predicateWithValue: [NSNumber numberWithInteger: MPMediaTypeMusic]
                                    forProperty: MPMediaItemPropertyMediaType
                                    ]];
        [query addFilterPredicate: [MPMediaPropertyPredicate
                                    predicateWithValue: [NSString stringWithUTF8String: artist_name.c_str()]
                                    forProperty: MPMediaItemPropertyArtist
                                    ]];
        [query setGroupingType: MPMediaGroupingAlbum];
        
        vector<PlaylistRef> albums;
        
        NSArray *query_groups = [query collections];
        for(MPMediaItemCollection *group in query_groups){
            PlaylistRef album = PlaylistRef(new Playlist(group));
            albums.push_back(album);
        }
        [query release];
        
        return albums;
    }
    
    vector<PlaylistRef> getArtists(){
        MPMediaQuery *query = [MPMediaQuery artistsQuery];
        vector<PlaylistRef> artists;
        NSArray *query_groups = [query collections];
        for(MPMediaItemCollection *group in query_groups){
            PlaylistRef artist = PlaylistRef(new Playlist(group));
            artists.push_back(artist);
        }
        return artists;
    }
    
} } // namespace cinder::itunes