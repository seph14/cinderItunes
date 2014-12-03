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

#include "Track.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation MPMediaItem (Readable)
- (id)readableValueForProperty:(NSString *)prop
{
    id originalValue = [self valueForProperty:prop];
    if (originalValue == nil) {
        return @"Unknown";
    }
    return originalValue;
}

@end

namespace cinder { namespace iTunes {
    
    ////////////////////////////////////////////////////////////////////////////
    // TRACK////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    Track::Track() : color(Color(1,1,1)) {}
    Track::Track(MPMediaItem* _media_item) : color(Color(1,1,1)) {
        mMediaItem = [_media_item retain]; }
    Track::~Track(){}
    
    TrackRef Track::create(MPMediaItem* _media_item){
        return std::shared_ptr<Track>( new Track(_media_item) );
    }
    
    string Track::getTitle(){
        return string([[mMediaItem readableValueForProperty: MPMediaItemPropertyTitle] UTF8String]);
    }
    
    string Track::getAlbumTitle(){
        return string([[mMediaItem readableValueForProperty: MPMediaItemPropertyAlbumTitle] UTF8String]);
    }
    
    string Track::getArtist(){
        return string([[mMediaItem readableValueForProperty: MPMediaItemPropertyArtist] UTF8String]);
    }
    
    string Track::getAssetUrl(){
        NSURL* location = [mMediaItem valueForProperty: MPMediaItemPropertyAssetURL];
        return string([location.absoluteString UTF8String]);
    }
    
    uint64_t Track::getAlbumId(){
        return [[mMediaItem valueForProperty: MPMediaItemPropertyAlbumPersistentID] longLongValue];
    }
    
    uint64_t Track::getArtistId(){
        return [[mMediaItem valueForProperty: MPMediaItemPropertyArtistPersistentID] longLongValue];
    }
    
    int Track::getPlayCount(){
        return [[mMediaItem valueForProperty: MPMediaItemPropertyPlayCount] intValue];
    }
    
    bool Track::isLocalTrack(){
        NSURL* assetURL = [mMediaItem valueForProperty:MPMediaItemPropertyAssetURL];
        if (!assetURL) return false;
        return true;
    }
    
    double Track::getLength(){
        return [[mMediaItem valueForProperty: MPMediaItemPropertyPlaybackDuration] doubleValue];
    }
    
    ////////////////////////////////////////////////////////////////////////////
    // PLAYLISt/////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    Playlist::Playlist(){}
    Playlist::Playlist(MPMediaItemCollection *_media_collection){
        NSArray *items = [_media_collection items];
        for(MPMediaItem *item in items){
            pushTrack(new Track(item));
        }
    }
    
    PlaylistRef Playlist::create(){
        return PlaylistRef( new Playlist() );
    }
    
    Playlist::~Playlist(){}
    
    void Playlist::clear(){
        tracks.clear();
    }
    
    void Playlist::pushTrack(TrackRef track){
        tracks.push_back(track);
    }
    
    void Playlist::pushTrack(Track *track){
        tracks.push_back(TrackRef(track));
    }
    
    string Playlist::getAlbumTitle(){
        MPMediaItem *item = [getMediaItemCollection() representativeItem];
        return string([[item valueForProperty: MPMediaItemPropertyAlbumTitle] UTF8String]);
    }
    
    string Playlist::getArtistName(){
        MPMediaItem *item = [getMediaItemCollection() representativeItem];
        return string([[item valueForProperty: MPMediaItemPropertyArtist] UTF8String]);
    }
    
    MPMediaItemCollection* Playlist::getMediaItemCollection(){
        NSMutableArray *items = [NSMutableArray array];
        for(Iter it = tracks.begin(); it != tracks.end(); ++it){
            [items addObject: ((*it)->getMediaItem())];
        }
        return ([MPMediaItemCollection collectionWithItems:items]);
    }
} } // namespace cinder::ipod
