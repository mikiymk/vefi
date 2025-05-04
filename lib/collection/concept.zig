/// 型がコレクションの概念に合致するかを判定する。
pub fn collection(T: type) bool {
 const match = Match.init(T);

 return match.hasDecl("Item") and
  match.decl("Item").is(type) and
  match.hasDecl("size");
}

/// 型がランダムアクセス可能かを判定する。
pub fn randomAccess(T: type) bool {
 const match = Match.init(T);

 return Bool.all(&.{
  match.hasDecl("Item"),
  match.hasDecl("size"),
 });
}
