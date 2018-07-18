// Copyright (c) 2017-present Mattermost, Inc. All Rights Reserved.
// See License.txt for license information.

package app

import (
	"github.com/mattermost/mattermost-server/mlog"
	"github.com/mattermost/mattermost-server/model"
)

func (a *App) SaveReactionForPost(reaction *model.Reaction) (*model.Reaction, *model.AppError) {
	post, err := a.GetSinglePost(reaction.PostId)
	if err != nil {
		return nil, err
	}

	if result := <-a.Srv.Store.Reaction().Save(reaction); result.Err != nil {
		return nil, result.Err
	} else {
		reaction = result.Data.(*model.Reaction)

		a.Go(func() {
			a.sendReactionEvent(model.WEBSOCKET_EVENT_REACTION_ADDED, reaction, post)
		})

		return reaction, nil
	}
}

func (a *App) GetReactionsForPost(postId string) ([]*model.Reaction, *model.AppError) {
	if result := <-a.Srv.Store.Reaction().GetForPost(postId, true); result.Err != nil {
		return nil, result.Err
	} else {
		return result.Data.([]*model.Reaction), nil
	}
}

func (a *App) getReactionCountsForPost(postId string) (model.PostReactionCounts, *model.AppError) {
	reactions, err := a.GetReactionsForPost(postId)
	if err != nil {
		return nil, err
	}

	reactionCounts := model.PostReactionCounts{}

	for _, reaction := range reactions {
		reactionCounts[reaction.EmojiName] += 1
	}

	return reactionCounts, nil
}

func (a *App) DeleteReactionForPost(reaction *model.Reaction) *model.AppError {
	post, err := a.GetSinglePost(reaction.PostId)
	if err != nil {
		return err
	}

	if result := <-a.Srv.Store.Reaction().Delete(reaction); result.Err != nil {
		return result.Err
	} else {
		a.Go(func() {
			a.sendReactionEvent(model.WEBSOCKET_EVENT_REACTION_REMOVED, reaction, post)
		})
	}

	return nil
}

func (a *App) sendReactionEvent(event string, reaction *model.Reaction, post *model.Post) {
	// send out that a reaction has been added/removed
	message := model.NewWebSocketEvent(event, "", post.ChannelId, "", nil)
	message.Add("reaction", reaction.ToJson())
	a.Publish(message)

	clientPost, err := a.PreparePostForClient(post)
	if err != nil {
		mlog.Error("Failed to prepare new post for client after reaction", mlog.Any("err", err))
	}

	// The post is always modified since the UpdateAt always changes
	a.InvalidateCacheForChannelPosts(post.ChannelId)

	clientPost.HasReactions = true
	clientPost.UpdateAt = model.GetMillis()

	umessage := model.NewWebSocketEvent(model.WEBSOCKET_EVENT_POST_EDITED, "", post.ChannelId, "", nil)
	umessage.Add("post", clientPost.ToJson())
	a.Publish(umessage)
}
