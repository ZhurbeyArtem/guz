---
name: wtf
description: Summarize an Asana task in one to four sentences - reads its title, description, comments and every thread they link to. Pass the task link or ID.
disable-model-invocation: true
---

# wtf

Tell the user what an Asana task is about and what it asks now, in one to four sentences.

## Read

1. Take the task GID from the user's input: a bare number, the number after `/task/` in an `app.asana.com/1/...`
   link, or the last number in an `app.asana.com/0/<project>/<task>` link.
2. Call the Asana MCP `get_task` with that GID, `comment_limit: 50`, `include_subtasks: false` and
   `opt_fields: name,notes,completed,assignee.name`. Without `opt_fields` the reply carries about 10 KB of
   custom-field enum options and no extra content; comments come back either way. When exactly 50 comments come
   back, read the older ones with `get_task_stories` and `resource_subtype: comment_added`.
3. Collect every thread link in `notes` and in each comment's `text`, and read each thread:
   - **Slack:** `https://<workspace>.slack.com/archives/<channel>/p<digits>`. Call `slack_read_thread` with that
     channel, `response_format: concise`, and the digits as a ts, with a dot before the last six
     (`p1700000000123456` → `1700000000.123456`). A link with `thread_ts=` points at a reply; pass its `thread_ts`
     instead.
   - **Asana task:** read it as in step 2.

   A `/profile/` link is a mention of a person. Notion, Figma and other documents are not threads. Read one level
   deep: a link inside a thread you opened stays unread.

The read is done when every thread link is read or listed as unreadable with its reason.

## Summarize

Write one to four sentences in the language the user writes in, under the adapted ASD-STE100 rules. They apply
here whether or not the `ste_writing` option is on. When they are not already in context, read them from
`../../hooks/ste-writing.sh`, relative to this skill's directory.

Lead with what the task asks now: the description sets the ask, and a later comment or thread can narrow or
replace it. Then say what blocks it or who must answer, when the task or a thread says so. Name the people,
fields, endpoints and numbers instead of describing them.

After the summary, add one line per unreadable link: the link and the reason.
