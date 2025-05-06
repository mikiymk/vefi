/// 型がコレクションの概念に合致するかを判定する。
pub fn collection(T: type) bool {
 const t = Match.init(T);

 return t.hasDecl("Item") and
  t.decl("Item").is(type) and
  t.hasMethod("size") and
  t.decl("size").returns(usize);
}

/// 型がインデックスでアクセス可能かを判定する。
pub fn indexed(T: type) bool {
 const match = Match.init(T);

 return t.hasMethod("get") and
  t.hasMethod("set");
}
