import 'post_category.dart';

enum PostType {
  // Marketplace
  forSale,
  freeItem,
  wanted,
  borrowRent,
  // Recommendations
  recTrades,
  recLifestyle,
  helpRequest,
  helpOffer,
  // Safety
  urgentAlert,
  securityAlert,
  // Lost & Found
  lostPet,
  foundPet,
  lostItem,
  foundItem,
  // Social
  event,
  hobbyPartner,
  discussion,
  // Jobs
  lookingForWork,
  hiring;

  String get displayName {
    switch (this) {
      case PostType.forSale:
        return 'For Sale';
      case PostType.freeItem:
        return 'Free / Freecycle';
      case PostType.wanted:
        return 'Looking to Buy';
      case PostType.borrowRent:
        return 'Borrow / Rent';
      case PostType.recTrades:
        return 'Trades Recommendation';
      case PostType.recLifestyle:
        return 'Lifestyle Recommendation';
      case PostType.helpRequest:
        return 'Looking for Help';
      case PostType.helpOffer:
        return 'Offering Help';
      case PostType.urgentAlert:
        return 'Urgent Alert';
      case PostType.securityAlert:
        return 'Security Alert';
      case PostType.lostPet:
        return 'Lost Pet';
      case PostType.foundPet:
        return 'Found Pet';
      case PostType.lostItem:
        return 'Lost Item';
      case PostType.foundItem:
        return 'Found Item';
      case PostType.event:
        return 'Event';
      case PostType.hobbyPartner:
        return 'Find a Partner';
      case PostType.discussion:
        return 'Discussion';
      case PostType.lookingForWork:
        return 'Looking for Work';
      case PostType.hiring:
        return 'Hiring';
    }
  }

  String get description {
    switch (this) {
      // Marketplace
      case PostType.forSale:
        return 'Sell items to your neighbours';
      case PostType.freeItem:
        return 'Give away items you no longer need';
      case PostType.wanted:
        return 'Looking to buy something from neighbours';
      case PostType.borrowRent:
        return 'Borrow or rent items temporarily';
      // Recommendations
      case PostType.recTrades:
        return 'Recommend tradespeople like plumbers, electricians, etc.';
      case PostType.recLifestyle:
        return 'Share lifestyle tips, restaurants, activities, etc.';
      case PostType.helpRequest:
        return 'Ask neighbours for help with something';
      case PostType.helpOffer:
        return 'Offer to help neighbours with tasks';
      // Safety
      case PostType.urgentAlert:
        return 'Report urgent safety issues requiring immediate attention';
      case PostType.securityAlert:
        return 'Share security concerns or suspicious activity';
      // Lost & Found
      case PostType.lostPet:
        return 'Report a missing pet';
      case PostType.foundPet:
        return 'Report a pet you have found';
      case PostType.lostItem:
        return 'Report a lost personal item';
      case PostType.foundItem:
        return 'Report an item you have found';
      // Social
      case PostType.event:
        return 'Organise a gathering or activity with a specific date and time';
      case PostType.hobbyPartner:
        return 'Find neighbours to share activities like sports, walking, book clubs, etc.';
      case PostType.discussion:
        return 'Start a general conversation or ask the community a question';
      // Jobs
      case PostType.lookingForWork:
        return 'Let neighbours know you are available for work';
      case PostType.hiring:
        return 'Post a job or task you need help with';
    }
  }

  String get contentLabel {
    switch (this) {
      case PostType.forSale:
        return 'What are you selling?';
      case PostType.freeItem:
        return 'What are you giving away?';
      case PostType.wanted:
        return 'What are you looking for?';
      case PostType.borrowRent:
        return 'What would you like to borrow?';
      case PostType.recTrades:
        return 'Who would you recommend?';
      case PostType.recLifestyle:
        return 'What would you recommend?';
      case PostType.helpRequest:
        return 'What do you need help with?';
      case PostType.helpOffer:
        return 'How can you help?';
      case PostType.urgentAlert:
        return "What's happening?";
      case PostType.securityAlert:
        return 'What have you noticed?';
      case PostType.lostPet:
        return 'Tell us about your pet';
      case PostType.foundPet:
        return 'Describe the pet you found';
      case PostType.lostItem:
        return 'What did you lose?';
      case PostType.foundItem:
        return 'What did you find?';
      case PostType.event:
        return 'Tell people about your event';
      case PostType.hobbyPartner:
        return 'What activity are you looking for?';
      case PostType.discussion:
        return "What's on your mind?";
      case PostType.lookingForWork:
        return 'Describe your skills';
      case PostType.hiring:
        return 'Describe the job';
    }
  }

  String get contentHint {
    switch (this) {
      case PostType.forSale:
        return 'Describe the item, its condition, and your asking price...';
      case PostType.freeItem:
        return 'Describe the item and any collection details...';
      case PostType.wanted:
        return "Describe the item you'd like to buy...";
      case PostType.borrowRent:
        return 'Describe what you need and for how long...';
      case PostType.recTrades:
        return "Share the tradesperson's details and your experience...";
      case PostType.recLifestyle:
        return "Tell us what you're recommending and why...";
      case PostType.helpRequest:
        return 'Describe what you need and when...';
      case PostType.helpOffer:
        return "Describe what you're offering and your availability...";
      case PostType.urgentAlert:
        return 'Describe the urgent issue and any actions to take...';
      case PostType.securityAlert:
        return 'Describe what you saw, when, and where...';
      case PostType.lostPet:
        return 'Describe your pet, where they were last seen, and any distinguishing features...';
      case PostType.foundPet:
        return 'Include what the pet looks like, where you found it, and where it is now...';
      case PostType.lostItem:
        return 'Describe the item and where you think you lost it...';
      case PostType.foundItem:
        return 'Describe the item and where you found it...';
      case PostType.event:
        return "Describe what's happening, who it's for, and anything people should bring...";
      case PostType.hobbyPartner:
        return "Describe the activity, when you'd like to do it, and any experience needed...";
      case PostType.discussion:
        return 'Start a conversation with your neighbours...';
      case PostType.lookingForWork:
        return 'Share what work you can do, your experience, and availability...';
      case PostType.hiring:
        return 'Share what needs doing, when, and any skills required...';
    }
  }

  String get dbValue {
    switch (this) {
      case PostType.forSale:
        return 'for_sale';
      case PostType.freeItem:
        return 'free_item';
      case PostType.wanted:
        return 'wanted';
      case PostType.borrowRent:
        return 'borrow_rent';
      case PostType.recTrades:
        return 'rec_trades';
      case PostType.recLifestyle:
        return 'rec_lifestyle';
      case PostType.helpRequest:
        return 'help_request';
      case PostType.helpOffer:
        return 'help_offer';
      case PostType.urgentAlert:
        return 'urgent_alert';
      case PostType.securityAlert:
        return 'security_alert';
      case PostType.lostPet:
        return 'lost_pet';
      case PostType.foundPet:
        return 'found_pet';
      case PostType.lostItem:
        return 'lost_item';
      case PostType.foundItem:
        return 'found_item';
      case PostType.event:
        return 'event';
      case PostType.hobbyPartner:
        return 'hobby_partner';
      case PostType.discussion:
        return 'discussion';
      case PostType.lookingForWork:
        return 'looking_for_work';
      case PostType.hiring:
        return 'hiring';
    }
  }

  PostCategory get category {
    switch (this) {
      case PostType.forSale:
      case PostType.freeItem:
      case PostType.wanted:
      case PostType.borrowRent:
        return PostCategory.marketplace;
      case PostType.recTrades:
      case PostType.recLifestyle:
      case PostType.helpRequest:
      case PostType.helpOffer:
        return PostCategory.recommendations;
      case PostType.urgentAlert:
      case PostType.securityAlert:
        return PostCategory.safety;
      case PostType.lostPet:
      case PostType.foundPet:
      case PostType.lostItem:
      case PostType.foundItem:
        return PostCategory.lostFound;
      case PostType.event:
      case PostType.hobbyPartner:
      case PostType.discussion:
        return PostCategory.social;
      case PostType.lookingForWork:
      case PostType.hiring:
        return PostCategory.jobs;
    }
  }

  static PostType fromString(String value) {
    switch (value) {
      case 'for_sale':
        return PostType.forSale;
      case 'free_item':
        return PostType.freeItem;
      case 'wanted':
        return PostType.wanted;
      case 'borrow_rent':
        return PostType.borrowRent;
      case 'rec_trades':
        return PostType.recTrades;
      case 'rec_lifestyle':
        return PostType.recLifestyle;
      case 'help_request':
        return PostType.helpRequest;
      case 'help_offer':
        return PostType.helpOffer;
      case 'urgent_alert':
        return PostType.urgentAlert;
      case 'security_alert':
        return PostType.securityAlert;
      case 'lost_pet':
        return PostType.lostPet;
      case 'found_pet':
        return PostType.foundPet;
      case 'lost_item':
        return PostType.lostItem;
      case 'found_item':
        return PostType.foundItem;
      case 'event':
        return PostType.event;
      case 'hobby_partner':
        return PostType.hobbyPartner;
      case 'discussion':
        return PostType.discussion;
      case 'looking_for_work':
        return PostType.lookingForWork;
      case 'hiring':
        return PostType.hiring;
      default:
        throw ArgumentError('Unknown post type: $value');
    }
  }

  static List<PostType> forCategory(PostCategory category) {
    return PostType.values.where((type) => type.category == category).toList();
  }
}
