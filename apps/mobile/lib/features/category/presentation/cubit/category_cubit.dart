import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/category_repository.dart';
import '../../domain/models/product_category.dart';
import 'category_state.dart';

class CategoryCubit
    extends Cubit<CategoryState> {
  CategoryCubit({
    required CategoryRepository repository,
  })  : _repository = repository,
        super(const CategoryInitial());

  final CategoryRepository _repository;

  Future<void> loadCategories({
    bool force = false,
  }) async {
    if (state is CategoryLoading) {
      return;
    }

    final currentState = state;

    if (!force &&
        currentState is CategoryReady &&
        currentState.categories.isNotEmpty) {
      return;
    }

    emit(const CategoryLoading());

    try {
      final categories =
          await _repository.getCategories();

      emit(
        CategoryReady(
          categories:
              List.unmodifiable(categories),
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to load categories',
        name: 'CategoryCubit',
        error: error,
        stackTrace: stackTrace,
      );

      emit(
        const CategoryError(
          type:
              CategoryErrorType.loadFailed,
        ),
      );
    }
  }

  Future<void> refreshCategories() {
    return loadCategories(force: true);
  }

  ProductCategory? findById(
    String categoryId,
  ) {
    final currentState = state;

    if (currentState
        is! CategoryReady) {
      return null;
    }

    for (final category
        in currentState.categories) {
      if (category.id == categoryId) {
        return category;
      }
    }

    return null;
  }
}