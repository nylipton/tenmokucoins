
import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationIndexCubit extends Cubit<int> {
  NavigationIndexCubit(int state) : super(state);

  setIndex( int ) => emit( int ) ;
}