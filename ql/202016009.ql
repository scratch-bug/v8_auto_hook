import cpp

class MapAffectingCall extends Call {
  MapAffectingCall() {
    exists(Function cal |
      cal = this.getTarget() and
      (
        cal.getQualifiedName().regexpMatch("(^|::)(Map::)?(Generalize|TryUpdate|Deprecate|Migrate|Reconfigure|Transition|CopyInsert|Normalize)($|::)")
        or cal.getQualifiedName().regexpMatch("(^|::).*Representation.*Generaliz.*($|::)")
        or cal.getQualifiedName().regexpMatch("(^|::).*Field.*Generaliz.*($|::)")
      )
    )
  }
}

class TransitionOrFieldUseCall extends Call {
  TransitionOrFieldUseCall() {
    exists(Function cal |
      cal = this.getTarget() and
      (
        cal.getQualifiedName().regexpMatch("(^|::)(Build|Generate|Visit|Reduce|Lower).*Store.*")
        or cal.getQualifiedName().regexpMatch("(^|::)(Build|Generate|Visit|Reduce|Lower).*Load.*")
        or cal.getQualifiedName().regexpMatch("(^|::).*Transition.*")
        or cal.getQualifiedName().regexpMatch("(^|::).*Field.*(Load|Store|Access).*")
        or cal.getQualifiedName().regexpMatch("(^|::).*Add(Data|Field).*")
      )
    )
  }
}

class DependencyInstallCall extends Call {
  DependencyInstallCall() {
    exists(Function cal |
      cal = this.getTarget() and
      (
        cal.getQualifiedName().regexpMatch("(^|::).*Dependenc(e|y).*(Add|Install|Record|Assume).*")
        or cal.getQualifiedName().regexpMatch("(^|::).*Deopt.*(Add|Trigger|Bailout).*")
        or cal.getQualifiedName().regexpMatch("(^|::)CompilationDependenc.*")
        or cal.getQualifiedName().regexpMatch("(^|::).*Assume.*(StableMap|NotDeprecated|Transition).*")
        or cal.getQualifiedName().regexpMatch("(^|::).*Record(Transition|Map).*")
      )
    )
  }
}

from Function f, MapAffectingCall src, TransitionOrFieldUseCall sink, int sl, int tl
where
  src.getEnclosingFunction() = f and
  sink.getEnclosingFunction() = f and
  sl = src.getLocation().getStartLine() and
  tl = sink.getLocation().getStartLine() and
  sl <= tl and
  not exists(DependencyInstallCall d, int dl |
    d.getEnclosingFunction() = f and
    dl = d.getLocation().getStartLine() and
    sl <= dl and dl <= tl
  )
select sink, sink.getLocation(),
  "Missing deopt/dependency after Map-affecting call: " +
  src.getTarget().getQualifiedName() + " -> " + sink.getTarget().getQualifiedName()
