# PachcaHandlers

Base project for creating simple bots or short commands for Pachca messenger

## Configuration

Set `PACHCA_API_KEY` in `.env`\
Migrate db `rake db:migrate`\
Or check `Dockerfile`

## Adding handlers

User defined handlers go to `lib/handlers`, custom clients - `lib/clients`

```ruby
class EchoHandler < BaseHandler
  title 'Echo'
  command 'echo'

  step :echo do
    intro 'This is a sample handler that echoes back the message you send in the chat.'
    field :message do
      name 'Message'
      description 'The message to echo back'
      validations [
        ->(value) { [!value.empty?, 'Message cannot be empty'] },
        ->(value) { [value.length <= 3, 'Message cannot be longer than 3 characters'] }
      ]
      callback { |ctx|
        Result.success("Echo: #{ctx[:value]}")
      }
    end
  end
end
```

<img src="g.gif">