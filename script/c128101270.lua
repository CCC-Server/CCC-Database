--Buster Link (가칭)
local s,id=GetID()
local CARD_ASSAULT_MODE=80280737 -- "버스터 모드"

-- 필요시 AddCodeList 정의
if aux.AddCodeList==nil then
	function aux.AddCodeList(c,...)
		local codes={...}
		for _,code in ipairs(codes) do
			local e1=Effect.CreateEffect(c)
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
			e1:SetCode(EFFECT_ADD_CODE)
			e1:SetValue(code)
			c:RegisterEffect(e1)
		end
	end
end

function s.initial_effect(c)
	-- 룰상 "버스터 모드"로 취급
	aux.AddCodeList(c,CARD_ASSAULT_MODE)

	--①: "버스터 모드" 언급 몬스터를 서치 or 특소
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end

-- 카드 참조용
s.listed_names={CARD_ASSAULT_MODE}
s.listed_series={0x104f} -- 버스터 모드 관련 시리즈 (정정됨)

---------------------------------------------------------------
-- ① "버스터 모드" 이름이 쓰인 몬스터 서치 or 특소
---------------------------------------------------------------
function s.thfilter(c,e,tp)
	return c:IsMonster() and c:ListsCode(CARD_ASSAULT_MODE)
		and (c:IsAbleToHand() or c:IsCanBeSpecialSummoned(e,0,tp,false,false))
end
function s.busterfilter(c)
	return c:IsFaceup() and (c:IsCode(CARD_ASSAULT_MODE) or c:IsSetCard(0x104f))
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil,e,tp)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bfield=Duel.IsExistingMatchingCard(s.busterfilter,tp,LOCATION_MZONE,0,1,nil)
	local g=Duel.GetMatchingGroup(s.thfilter,tp,LOCATION_DECK,0,nil,e,tp)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local sg=g:Select(tp,1,1,nil)
	local tc=sg:GetFirst()
	if not tc then return end
	if bfield and tc:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.SelectYesNo(tp,aux.Stringid(id,1)) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
			Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
		end
	else
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	end

	-- 이 턴 동안 싱크로 몬스터만 엑덱에서 특소 가능
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(e,c) return not c:IsType(TYPE_SYNCHRO) and c:IsLocation(LOCATION_EXTRA) end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
