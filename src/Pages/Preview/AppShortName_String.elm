module Pages.Preview.AppShortName_String exposing (Model, Msg, Params, page)

import Api
import Components.ManifestOutputs as ManifestOutputs
import Components.ManifestViewer as ManifestViewer
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Json.Encode as Encode
import Manifest exposing (Manifest)
import Manifest.Color
import Material.Icons.Outlined as MaterialIcons
import Material.Icons.Types exposing (Coloring(..))
import Session exposing (Session)
import Shared
import Spa.Document exposing (Document)
import Spa.Generated.Route as Route
import Spa.Page as Page exposing (Page)
import Spa.Url as Url exposing (Url)
import Task
import UI.Colors as Colors exposing (Colors)
import Url


page : Page Params Model Msg
page =
    Page.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        , save = save
        , load = load
        }



-- INIT


type alias Params =
    { appShortName : String }


type alias Model =
    { session : Session
    , device : Device
    , appShortName : String
    , colors : Colors
    , manifest : Maybe Manifest
    }


init : Shared.Model -> Url Params -> ( Model, Cmd Msg )
init shared { params } =
    let
        appShortName =
            case Url.percentDecode params.appShortName of
                Just name ->
                    name

                Nothing ->
                    "Short name decoding failed"

        maybeManifest =
            List.head <|
                List.filter
                    (\manifest -> manifest.shortName == appShortName)
                    shared.manifests

        colors =
            case maybeManifest of
                Just manifest ->
                    { backgroundColor =
                        Maybe.withDefault Colors.lightPurple <|
                            Manifest.Color.fromHex manifest.backgroundColor
                    , themeColor =
                        Maybe.withDefault Colors.lightPurple <|
                            Manifest.Color.fromHex manifest.themeColor
                    , fontColor =
                        Maybe.withDefault Colors.black <|
                            Manifest.Color.contrast manifest.backgroundColor
                    , themeFontColor =
                        Maybe.withDefault Colors.black <|
                            Manifest.Color.contrast manifest.themeColor
                    }

                Nothing ->
                    Colors.init
    in
    ( { session = shared.session
      , device = shared.device
      , appShortName = appShortName
      , colors = colors
      , manifest = maybeManifest
      }
      -- elm-spa needs an update to sync to Shared
    , Task.perform (\_ -> SyncShared) (Task.succeed Nothing)
    )



-- UPDATE


type Msg
    = SyncShared
    | CopyToClipboard String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SyncShared ->
            ( model, Cmd.none )

        CopyToClipboard elemId ->
            ( model
            , Api.copyToClipboard (Encode.string elemId)
            )


save : Model -> Shared.Model -> Shared.Model
save model shared =
    { shared | colors = model.colors }


load : Shared.Model -> Model -> ( Model, Cmd Msg )
load shared model =
    let
        maybeManifest =
            List.head <|
                List.filter
                    (\manifest -> manifest.shortName == model.appShortName)
                    shared.manifests
    in
    ( { model
        | session = shared.session
        , device = shared.device
        , manifest = maybeManifest
      }
    , Task.perform (\_ -> SyncShared) (Task.succeed Nothing)
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    { title = "Previewing " ++ model.appShortName
    , body =
        [ case model.manifest of
            Just manifest ->
                case model.device.class of
                    Phone ->
                        column
                            [ width fill
                            , height fill
                            , paddingXY 10 20
                            ]
                            [ ManifestViewer.view
                                { manifest = manifest
                                , fontColor = model.colors.fontColor
                                }
                            ]

                    Tablet ->
                        case model.device.orientation of
                            Portrait ->
                                column
                                    [ width fill
                                    , height fill
                                    , paddingXY 10 20
                                    , spacing 20
                                    ]
                                    [ ManifestViewer.view
                                        { manifest = manifest
                                        , fontColor = model.colors.fontColor
                                        }
                                    ]

                            Landscape ->
                                column
                                    [ centerX
                                    , width fill
                                    , height fill
                                    , paddingXY 30 30
                                    , spacing 30
                                    ]
                                    [ row [ width fill, spacing 25 ]
                                        [ ManifestViewer.view
                                            { manifest = manifest
                                            , fontColor = model.colors.fontColor
                                            }
                                        , ManifestOutputs.view
                                            { manifest = manifest
                                            , onCopyToClipboard = CopyToClipboard
                                            }
                                        ]
                                    ]

                    _ ->
                        column
                            [ centerX
                            , width (px 1000)
                            , height fill
                            , paddingXY 30 30
                            , spacing 30
                            ]
                        <|
                            [ row [ width fill, spacing 25 ]
                                [ ManifestViewer.view
                                    { manifest = manifest
                                    , fontColor = model.colors.fontColor
                                    }
                                , ManifestOutputs.view
                                    { manifest = manifest
                                    , onCopyToClipboard = CopyToClipboard
                                    }
                                ]
                            ]

            Nothing ->
                viewLoadingAnimation
        ]
    }


viewLoadingAnimation : Element Msg
viewLoadingAnimation =
    column [ width fill, padding 20 ] [ el [ centerX ] (text "Loading animation goes here") ]
