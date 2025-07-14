class AnswerSheetRecomputeParams {
  bool shouldRecomputeAllCards;
  bool reapplyTemplate;

  AnswerSheetRecomputeParams({
    this.shouldRecomputeAllCards = true,
    this.reapplyTemplate = false,
  });

  //copy with

  AnswerSheetRecomputeParams copyWith({
    bool? shouldRecomputeAllCards,
    bool? reapplyTemplate,
  }) {
    return AnswerSheetRecomputeParams(
      shouldRecomputeAllCards:
          shouldRecomputeAllCards ?? this.shouldRecomputeAllCards,
      reapplyTemplate: reapplyTemplate ?? this.reapplyTemplate,
    );
  }
}
