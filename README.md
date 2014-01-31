# Grove

[![Build Status](https://semaphoreapp.com/api/v1/projects/35b20ab7aed8961031350862490b0bc555b9d6dc/28279/badge.png)](https://semaphoreapp.com/projects/1580/branches/28279)

Grove is a generic document store layered on top of an actual database such as PostgreSQL. It can store and index structured documents like comments, blog posts, events etc. and organize these documents for easy retrieval later.

## Data model

In Grove, a document is any dictionary-type object that can be represented with a JSON hash, including nested hashes. Grove organizes these documents inside _posts_; a post represents the "posting" of a document. _All Grove APIs deal with posts, not documents directly_.

A post collects the following information:

* **UID** — a unique ID (see later section on UIDs).
* **Class** — a class which indicates the type of document, typically being application-specific. Grove classes always have the prefix `post.`, eg. `post.comment`.
* **Paths** — paths that the document is associated with (there must be at least one).
* **Tags** — a list of simple string tags.
* **Timestamps** — timestamps for retrieving documents on a timeline.
* **Document** — the document proper.

### Document class

The document class is an application-specific **period-delimited string of identifiers**. This can be used to filter queries, and can be used to distinguish documents of different types from each other.

Examples of typical class names:

- `post.blog`
- `post.event`
- `post.user_profile`

Note that the first identifier must always be `post`. This signals to other applications that this specific object is handled by Grove.

### Paths

Grove's document database can be viewed as a hierarchy of folders. Every document must be associated with at least one path. Paths with wildcards are typically used to query Grove for content.

**A path is a period-delimited list of folder names**. The first name must be the *realm* of the document (see [Checkpoint](http://github.com/bengler/checkpoint) for more on realms). The second name is by convention an application identifier, while the rest of the path is application-specific.

Examples of paths:

- `acmecorp.calendarapp.events.facebook`
- `acmecorp.blogs.postings`
- `acmecorp.blogs.football.postings`
- `acmecorp.users`

A document has one *canonical path*, which is where the "original" document is stored. If you need the document to appear in multiple places in the folder hierarchy you may post it to multiple paths, which will act like "symlinks" to the document, and enable the  todocument appear in query results as if it were stored in all the provided paths; in reality, the original document is always returned. If the underlying document is updated, it will be updated for all paths.

Folders are created automatically whenever a document is posted; you don't have to manually create them. Any path you postulate is acceptable as long as it is within the _realm_ of your application.

#### Child objects

It is a convention in Pebble applications to put children of an object in a "subfolder" of its canonical path. A subpath is (conventionally) generated by appending the numeric ID of the parent object to the path and storing the children there.

For example, an article in the football blog:

    post.article:acmecorp.blogs.football$323
    
The numeric ID here is `323`. Comments on that article would be inside the path:

    post.comment:acmecorp.blogs.football.323

A comment posted to that path would get an UID such as this:

    post.comment:acmecorp.blogs.football.323$534

### Tags

A set og tags may be applied to any document and subsequently be used to constrain results in queries. A tag is **an opaque identifier that may contain letters, digits and underscores** (but not spaces).

### Occurrences

A document may also be organized on a timeline. A document may have any number of timestamps (occurrences) attached to it. Each timestamp is labeled. This can be used to model start-/end-times for events, or due dates for tasks.

When querying Grove, the result set can be constrained to documents with a specific labeled occurrence and optionally only documents with such an occurrence within a specified time window. This would typically be used to retrieve events that occur on a specific date, or tasks that are overdue.

### Synchronization from external sources

When synchronizing data from external sources, you should give the document an **external ID** (`external_id`). The external ID may be any string, it may e.g. be the URL or database ID of the source object. The important thing is that it is invariant for the given source object, and that it is unique within the realm of your application. This ensures that updates written by multiple concurrent workers never results in duplicates.

Additionally, Grove supports **external documents**. If the content of the source document is synchronized to Grove as an `external_document` (not `document`) and local edits are written to the `document` field, Grove ensures that consecutive synchronization operations will not overwrite local edits, while fields that do not have local edits will still be updated from source. An example:

- An event is synchronized from facebook to Grove. The fields are written to the `external_document`, `document` is blank.
- An editor determines that the title of the event is unhelpful ("Big Launch!!!") and creates a local edit writing `{"title": "Launch of the new Wagner Niebelung Ring Lego Kits!!!"}`
- The document now contains the key `title` while the rest of the content is in `external_document`.
- A client requesting the document will see the merged content of `external_document` and `document`.
- An updated event is synchronized from facebook. The updated document is written to `external_document`. The body and title of the source document has been updated from the source.
- A client requesting the document sees the updated body, while the title is overridden by the content of document.
- Since the external_document is newer than the document and an updated field is overridden the document is now marked as "conflicted" in Grove. An application may provide an interface to the user to resolve this conflict and update the `document`.

### UIDs

Across all pebbles Grove documents are identified by their UIDs. The UID of a Grove document always has base class `post`. UIDs have the format:

    <klass>:<canonical path>$<id>

Typical UIDs will look like this:

- `post.event:acmecorp.calendarapp.events.facebook$121`
- `post.comment:acmecorp.blogs.fotball.postings.121$453211`

## Custom policies

Grove supports Checkpoint callbacks. You may override Grove's internal rules about who has permissions to create, update and delete what by implementing callbacks. See [Checkpoint's documentation](https://github.com/bengler/checkpoint/blob/master/README.md) for details on how to do this.

## Fancy fields, we should explain their intended use
document
protected
external_document
tags
occurences
published
deleted
sensitive


## API

### Querying

To query for one or more documents, one performs as `GET` to:

    /api/grove/v1/posts/<UID>?...
    
For example:

    /api/grove/v1/posts/post:acmecorp.*?tags=unpaid

The UID part is the class, path and ID to search, and forms the basic query. All parts of this UID can contain wildcards, eg. `*:acmecorp.invoices.*`.

Additional parameters:

* `external_id`: Filter by external ID.
* `tags`: Constrain query by tags. Either a comma separated list of required tags or a boolean expression like 'paris & !texas' or 'closed & (failed | pending)'.
* `created_by`: Filter by documents created by a Checkpoint identity (specified by UID).
* `created_after`: Filter by documents created after this date (ISO 8601 date).
* `created_before`: Filter by documents created before this date (ISO 8601 date).
* `unpublished`: Either `include` (accessible unpublished posts will be included with the result) or `only` (only accessible unpublished posts will be included with the result). The default is to only include published documents. 
* `deleted`: If `include`, accessible deleted posts will be included with the result. The default is to exclude deleted documents.
* `occurrence[label]`: Require that the post have an occurrence with the label specified in this parameter.
* `occurrence[from]`: The occurrences must be later than this timestamp (ISO 8601 timestamp).
* `occurrence[to]`: The occurrences must be earlier than this timestamp (ISO 8601 timestamp).
* `occurrence[order]`: Order either by `asc` (ascending) or `desc` (descending).
* `limit`: The maximum amount of posts to return.
* `offset`: The index of the first result to return (for pagination).
* `sort_by`: Field to sort by. Defaults to `created_at`.
* `direction`: Direction of sort, either `desc` (descending; default) or `asc` (ascending).
