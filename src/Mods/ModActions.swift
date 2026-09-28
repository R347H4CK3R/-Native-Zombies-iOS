import Foundation
#if DEV_MOD_MENU
final class ClosureModAction: ModAction {
    let id:String; let title:String; let category:ModCategory; private let body:()->Void
    init(_ id:String,_ title:String,_ category:ModCategory,_ body:@escaping()->Void){self.id=id;self.title=title;self.category=category;self.body=body}
    func execute(){body()}
}
final class ClosureModToggle: ModToggle {
    let id:String; let title:String; let category:ModCategory; private let readValue:()->Bool; private let writeValue:(Bool)->Void
    init(_ id:String,_ title:String,_ category:ModCategory,get:@escaping()->Bool,set:@escaping(Bool)->Void){self.id=id;self.title=title;self.category=category;self.readValue=get;self.writeValue=set}
    var isEnabled:Bool{readValue()}
    func execute(){writeValue(!readValue())}
    func setEnabled(_ enabled:Bool){writeValue(enabled)}
}
#endif
