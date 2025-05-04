pub fn collection(T: type) bool {
 const match = Match.init(T);

 return Bool.all(&.{
  match.hasDecl("Item"),
  match.hasDecl("size"),
 });
}
