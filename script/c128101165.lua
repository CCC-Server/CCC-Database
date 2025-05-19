--RR-스트래프 블레이커
local s,id=GetID()
function s.initial_effect(c)
	-- ① 패 공개 후 특수 소환 + 엑시즈
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- ② 패 이외에서 묘지로 보내졌을 때 회수
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,2})
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- ① 메인 페이즈에서만 발동 가능
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end

-- RR 레벨 4 몬스터 필터
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xba) and c:IsLevel(4) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
			and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
			and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND,0,1,c,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
	if not c:IsRelateToEffect(e) or not c:IsCanBeSpecialSummoned(e,0,tp,false,false) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND,0,1,1,c,e,tp)
	if #g==0 then return end
	local rc=g:GetFirst()
	Duel.ConfirmCards(1-tp,Group.FromCards(c,rc))

	if Duel.SpecialSummonStep(c,0,tp,tp,false,false,POS_FACEUP)
		and Duel.SpecialSummonStep(rc,0,tp,tp,false,false,POS_FACEUP) then
		Duel.SpecialSummonComplete()

		local mat=Group.FromCards(c,rc)
		-- 레벨 체크: 두 몬스터가 동일한 레벨이어야 함
		local lv=c:GetLevel()
		if rc:GetLevel()~=lv then return end

		local xyz_candidates=Duel.GetMatchingGroup(function(xc)
			return xc:IsType(TYPE_XYZ) and xc:IsSetCard(0xba)
				and xc:GetRank()==lv
				and xc:IsCanBeSpecialSummoned(e,SUMMON_TYPE_XYZ,tp,false,false)
		end, tp, LOCATION_EXTRA, 0, nil)

		if #xyz_candidates>0 then
			Duel.BreakEffect()
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local xyz=xyz_candidates:Select(tp,1,1,nil):GetFirst()
			if xyz then
				xyz:SetMaterial(mat)
				Duel.Overlay(xyz,mat)
				Duel.SpecialSummon(xyz,SUMMON_TYPE_XYZ,tp,tp,false,false,POS_FACEUP)
				xyz:CompleteProcedure()
			end
		end
	end
end

-- ② 패 이외에서 묘지로 갔을 때 회수
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return not e:GetHandler():IsPreviousLocation(LOCATION_HAND)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,e:GetHandler(),1,0,0)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SendtoHand(c,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,c)
	end
end
