--Advent of the Black Flame Dragon (가칭)
local s,id=GetID()
local SET_HORUS=0x1003  -- "Horus the Black Flame Dragon" 카드군
local CARD_OVERLORD=128101421  -- "Horus the Black Flame Dragon Deity - Overlord"

function s.initial_effect(c)
	--------------------------------------
	-- 항상 "호루스의 흑염룡" 카드로 취급
	--------------------------------------
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetRange(LOCATION_ALL)
	e0:SetValue(SET_HORUS)
	c:RegisterEffect(e0)

	--------------------------------------
	-- (1) 발동 : ① / ② 중 1개 선택
	--------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0)) -- "Activate 1 of these effects."
	e1:SetCategory(CATEGORY_RELEASE+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.efftg)
	e1:SetOperation(s.effop)
	c:RegisterEffect(e1)
end

--------------------------------------------------
-- 공통 : 오버로드 / 소재 관련 보조 함수
--------------------------------------------------
-- 의식할 몬스터: 항상 Overlord
local function ovfilter(c)
	return c:IsCode(CARD_OVERLORD)
end

-- 덱에서 의식 소재로 쓸 몬스터 (2번 효과용)
function s.deckmatfilter(c)
	return c:IsType(TYPE_MONSTER) and c:IsReleasableByEffect()
end
function s.extragroup(e,tp,eg,ep,ev,re,r,rp,chk)
	return Duel.GetMatchingGroup(s.deckmatfilter,tp,LOCATION_DECK,0,nil)
end
function s.extraop(mat,e,tp,eg,ep,ev,re,r,rp,tc)
	-- 필드/패 소재는 ReleaseRitualMaterial로 처리, 덱 소재는 묘지로
	local mat2=mat:Filter(Card.IsLocation,nil,LOCATION_DECK)
	mat:Sub(mat2)
	Duel.ReleaseRitualMaterial(mat)
	if #mat2>0 then
		Duel.SendtoGrave(mat2,REASON_EFFECT|REASON_MATERIAL|REASON_RITUAL|REASON_RELEASE)
	end
end

-- 2번 효과의 "최대 2장" 제한
function s.tributelimit(e,tp,g,sc)
	-- 첫 값: 허용, 두 번째 값: 금지 조건
	return #g<=2,#g>2
end

--------------------------------------------------
-- (1) 타깃 지정 : ① 덱 / ② 패 중 선택
--------------------------------------------------
function s.efftg(e,tp,eg,ep,ev,re,r,rp,chk)
	-- ① 덱에서 오버로드 의식
	local params1={
		lvtype=RITPROC_EQUAL,
		filter=aux.FilterBoolFunction(ovfilter),
		location=LOCATION_DECK,                      -- 의식 몬스터 위치
		matfilter=aux.FilterBoolFunction(Card.IsType,TYPE_MONSTER) -- 기본 소재: 패/필드 몬스터
	}
	-- ② 패에서 오버로드 의식 (소재는 패/필드/덱, 최대 2장)
	local params2={
		lvtype=RITPROC_EQUAL,
		filter=aux.FilterBoolFunction(ovfilter),
		location=LOCATION_HAND,                     -- 의식 몬스터 위치(기본값이지만 명시)
		matfilter=aux.FilterBoolFunction(Card.IsType,TYPE_MONSTER),
		extrafil=s.extragroup,
		extraop=s.extraop,
		forcedselection=s.tributelimit
	}

	local b1=Ritual.Target(params1)(e,tp,eg,ep,ev,re,r,rp,0)
	local b2=Ritual.Target(params2)(e,tp,eg,ep,ev,re,r,rp,0)
	if chk==0 then return b1 or b2 end

	local op=Duel.SelectEffect(tp,
		{b1,aux.Stringid(id,1)}, -- ● 덱에서 의식
		{b2,aux.Stringid(id,2)}) -- ● 패에서 의식
	e:SetLabel(op)
	if op==1 then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
		Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,1,tp,LOCATION_HAND+LOCATION_MZONE)
	elseif op==2 then
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
		Duel.SetOperationInfo(0,CATEGORY_RELEASE,nil,1,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_DECK)
	end
end

--------------------------------------------------
-- (1) 발동 처리
--------------------------------------------------
function s.effop(e,tp,eg,ep,ev,re,r,rp)
	local op=e:GetLabel()
	-- ① 덱에서 의식
	if op==1 then
		local params1={
			lvtype=RITPROC_EQUAL,
			filter=aux.FilterBoolFunction(ovfilter),
			location=LOCATION_DECK,
			matfilter=aux.FilterBoolFunction(Card.IsType,TYPE_MONSTER)
		}
		Ritual.Operation(params1)(e,tp,eg,ep,ev,re,r,rp)
	-- ② 패에서 의식 (패/필드/덱 소재, 최대 2장)
	elseif op==2 then
		local params2={
			lvtype=RITPROC_EQUAL,
			filter=aux.FilterBoolFunction(ovfilter),
			location=LOCATION_HAND,
			matfilter=aux.FilterBoolFunction(Card.IsType,TYPE_MONSTER),
			extrafil=s.extragroup,
			extraop=s.extraop,
			forcedselection=s.tributelimit
		}
		Ritual.Operation(params2)(e,tp,eg,ep,ev,re,r,rp)
	end
end
