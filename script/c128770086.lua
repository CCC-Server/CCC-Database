-- 포츈 퓨처 텔링
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 발동시 덱에서 "포츈 레이디" 카드명이 쓰인 마함 세트
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetOperation(s.setop)
	c:RegisterEffect(e1)
	-- ②: 레벨 상승시 서치 or 소생
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_CUSTOM+id)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	-- 전역 레벨 체크
	if not s.global_check then
		s.global_check=true
		local ge=Effect.CreateEffect(c)
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetCode(EVENT_ADJUST)
		ge:SetOperation(s.checkop)
		Duel.RegisterEffect(ge,0)
	end
end

---- ① 덱 세트 필터 & 오퍼레이션
local special_codes = {
	[68663748]  = true,  -- 타임 패시지
	[94068856]  = true,  -- 운명만곡
	[91407982]  = true,  -- 포츈 퓨처
	[94662235]  = true,  -- 포츈 비전
}
function s.setfilter(c)
	local code=c:GetCode()
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
	   and code~=id
	   and c:IsSSetable()
	   and ( c:IsSetCard(0x31) or special_codes[code] )
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
		Duel.ConfirmCards(1-tp,g)
	end
end

---- ② 레벨 상승 감지 & 커스텀 이벤트 발생
-- Fortune Lady 몬스터 필터
function s.lvfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:IsSetCard(0x31)
end
-- EVENT_ADJUST 시 매 프레임 레벨 비교
function s.checkop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.lvfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	for tc in aux.Next(g) do
		local lv=tc:GetLevel()
		local prev_lv=tc:GetFlagEffectLabel(id)
		if prev_lv==nil then
			-- 최초 등장: 레벨 기록만 하고 이벤트 발생 안 함
			tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,lv)
		elseif prev_lv~=lv then
			-- 기존값과 다르면 레벨이 바뀐 것으로 간주
			tc:ResetFlagEffect(id)
			tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,lv)
			Duel.RaiseEvent(tc,EVENT_CUSTOM+id,e,0,tc:GetControler(),tc:GetControler(),0)
		end
	end
end


function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- eg에 레벨이 바뀐 Fortune Lady 몬스터가 있으면 발동
	return eg and eg:IsExists(s.lvfilter,1,nil)
end

---- ② 서치/스펙오퍼레이션
function s.thfilter(c)
	return c:IsSetCard(0x31) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x31) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
			or Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
	local opt=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
	if opt==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	else
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end
