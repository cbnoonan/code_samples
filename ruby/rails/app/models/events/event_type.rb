class EventType < ActiveRecord::Base
  include Aspera::ActiveRecord::Common

  has_many :events

  attr_accessible :event_class
  
  class << self
    
    DATA = [
      {:event_class => 'DirectoryCreatedOnNodeEvent'},
      {:event_class => 'DirectoryCreatedOnShareEvent'},
      {:event_class => 'DirectoryStatusChangedEvent'},
      {:event_class => 'FailedLoginEvent'},
      {:event_class => 'FileRenamedOnNodeEvent'},
      {:event_class => 'FileRenamedOnShareEvent'},
      {:event_class => 'FilesDeletedFromNodeEvent'},
      {:event_class => 'FilesDeletedFromShareEvent'},
      {:event_class => 'ForgotPasswordEvent'},
      {:event_class => 'LocalUserCreatedEvent'},
      {:event_class => 'LocalUserDeletedEvent'},
      {:event_class => 'LoginEvent'},
      {:event_class => 'LogoutEvent'},
      {:event_class => 'NodeCreatedEvent'},
      {:event_class => 'NodeDeletedEvent'},
      {:event_class => 'NodeStatusChangedEvent'},
      {:event_class => 'OwnEmailChangedEvent'},
      {:event_class => 'OwnPasswordChangedEvent'},
      {:event_class => 'SessionTimedOutEvent'},
      {:event_class => 'ShareAuthorizationCreatedEvent'},
      {:event_class => 'ShareCreatedEvent'},
      {:event_class => 'ShareDeletedEvent'},
      {:event_class => 'ShareStatusChangedEvent'},
      {:event_class => 'SmtpServerStatusChangedEvent'},
      {:event_class => 'TestEmailRequestedEvent'},
      {:event_class => 'TransferCompletedEvent'},
    ]
    
    def init
      delete_all
      DATA.each do |attributes|
        create! attributes
      end
    end
  end
end